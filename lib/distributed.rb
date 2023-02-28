require 'drb'

=begin rdoc

=begin rdoc 
This file provides functionality related to the caching method results.

Method +make_distributed+ allows to create distributed versions of existing methods.
It should be used within Module or Class context.

"Distribute method" means "make only one ruby VM (among several ruby VMs running 
on several machines) responsible for calculating this method results". 
Usage of distributed methods is transparent. 
First call of distributed method of an object in any ruby VM brings to creating DRbMaster
proxing this object.

class A
  def a
    ..
  end
  make_distributed :b, # new mehod
    :method=>:a, # existing method for which we want to define
                 # distributed version; if skipped then equal to :b
    :ports=>9000..9001,
    :host=>'localhost', # default is 127.0.0.1
    :distribute_by=>:any,
    :remote_results=>true # Method returns references to remote object if true. Default is false.
end


If several ruby instances run simultaneously, 
then all calls to distributed method :b are "redirected" (via DRb) to 
the only one object living in in one ruby VM where 
first call to the method :b had place.


  Examples:
  class RelevanceMaster
    # Distributed factory
    class <<self
      make_distributed :new, :method=>new,  
        :host=>127.0.0.0, # use 0.0.0.0 if you want to permit access from outer world.
        :ports=>(9000..9001) # specify several ports if you want to rescue yourself
                             # from factory death or timeout
                             # 
    end
    
    def initialize
      @count = 0
    end
    
    def hi
      @count += 1
      puts @count
    end
  end
  
  # Ruby instance 1:
      m = RelevanceMaster.master
      m.hi # => 1
      m.hi # => 2
      loop {}
  # Ruby instance 2:
      m = RelevanceMaster.master
      m.hi # => 3
      m.hi # => 4
      
In options one can specify 
  * :remote_ports (usualy range) and :remote_host (ip address) define *remote url range*. I will look
    through these urls trying to find  DRbObject proxing object with required method. One can 
    directly specify option :remote_urls (value should be enumerable). 
    If remote url range is not defined than local url range will be used. 
    
  * :ports (usualy range) and :host (localhost, 127.0.0.1, ip address binded to local machine) define
    *local url range*. I try to bind Drb master to the first free url from this range if no remote
    DRbObject distributing reqired method is found. One can specify local url range directly using
    option :urls:
    
       make_distributed :drb_method_name, :method_name,
         :urls=>('druby://127.0.0.1:9000'..'druby://127.0.0.1:9100'),
         :remote_urls=>['druby://192.168.0.1:9000','druby://192.168.0.2:9000']

  * :distribute_by -- scope where I will save information about methods the object distributes. 
    Allowed values are :global, :class, :object, or :any.  Default is :any.
    If value is :any then distributed method tries to find any DRbObject responding to required
    method. If value is :object, then responding to method is not enough; object should be 
    registered as distributing the method. If value is :class then object class should be 
    registered as distributing the method. If value is :global then ruby instance should be 
    registered as distributing the method. Registration has place in the moment of creating 
    DRb master.
    Value of :distribute_by does matter only if you want one object to distribute more than one
    methods.
    
  * :remote_results -- method returns references to remote object if true. Default is false. 
    Note, that undumpable objects (like Proc or Method) are always returned as references to remote object.
=end

class Object
  def singleton_class
    @singleton_class ||= class <<self;  self; end rescue nil
  end
end

def make_distributed(drb_method, params={})
  require 'logger'
  __logger ||= params[:logger] || Logger.new(STDOUT)

  distribute_by = params[:distribute_by] || :any
    
  orig_method = (params[:method] || drb_method).to_sym
  drb_urls = remote_drb_urls = nil
  if params[:ports]
    host = params[:host] || '127.0.0.1' 
    ports = params[:ports].to_a.sort
    drb_urls = (("druby://#{host}:#{ports.first.to_s}")..("druby://#{host}:#{ports.last.to_s}"))
  else
    drb_urls = params[:urls] || ('druby://127.0.0.1:9300'..'druby://127.0.0.1:9400')
  end

  if params[:remote_ports] || params[:remote_host]
    host = params[:remote_host] || params[:host]
    ports = (params[:remote_ports] || params[:ports]).to_a.sort
    remote_drb_urls = (("druby://#{host}:#{ports.first.to_s}")..("druby://#{host}:#{ports.last.to_s}"))
  else
    remote_drb_urls = params[:remote_urls] || drb_urls
  end

  has_remote_results = params[:remote_results] || false
  if drb_method == orig_method
    orig_method =  "#{orig_method}_orig".to_sym
    self.class_eval "alias :#{orig_method} :#{drb_method}"
  end

  attr_accessor :__distributor, :drb_master, :drb_url
  def distribute?(meth)
    self.respond_to?(meth) && __distributor[meth]
  end
  
  case distribute_by
  when :class
    @@__distributor ||= {}
    @@__distributor[drb_method] = true
    find_distributor = lambda do |o,drb_method|
      @@__distributor ||= {}
    end
  when :global
    $__distributor ||= {}
    $__distributor[drb_method] = true
    find_distributor = lambda do |o,drb_method|
      $__distributor ||= {}
    end
  when :object
    find_distributor = lambda do |o,drb_method|
      o.__distributor ||= {}  
    end
  when :any
    find_distributor = lambda do |o,drb_method|
      Hash.new {|h,m| true}
    end
  else
    raise ArgumentError, "Bad value '#{distribute_by}' for parameter :distribute_by"
  end
  
  master = nil
  
  find_master = lambda do |meth|
    return master if master
    DRb.start_service()
    drb_urls.each do |url|
      begin 
        master = DRbObject.new(nil, url)
        break if master.distribute?(meth)
      rescue Exception=>e
        master = nil
      end
    end
    master
  end
  
  self.send(:define_method, drb_method) do |*args|
    # __logger.debug "#{self}\##{drb_method} (distributed)"
    if master
      __logger.debug "Known master '#{master}'" 
    else
      master ||= find_master[drb_method]
      __logger.debug "Found master '#{master}'" if master
    end
    unless master
      master = self
      # value of option :distribute_by should be unique for each master, because
      # __distributor returns hash living in global, class, or object space.
      master.__distributor = find_distributor[master, drb_method]
      master.__distributor[drb_method] = master
      
      drb_urls.each do |url|
        begin
          master.drb_master = DRb.start_service(url, master)
          master.drb_url = url
          __logger.debug "Started drb service for master '#{self}' at url '#{url}'"
          break
        rescue Exception=>e
          # port is in use, it's ok 
          __logger.debug "#{e.to_s}\n#{e.backtrace[0..3].join("\n")}"
        end
      end
    end
    unless master.drb_url
      __logger.error "Master '#{self}' can't put himself on a url from '#{drb_urls}'"
    end
    # __logger.debug "#{master}\##{orig_method} (orig)"
    result = master.send(orig_method, *args)
    if has_remote_results && result.singleton_class && !result.class.include?(DRbUndumped)
      result.singleton_class.extend(DRbUndumped)
    end
    result
  end
end

if $0 == __FILE__
  require File.dirname(__FILE__) + '/cached'
  class FibonacciMaster
    class <<self # we want to make class our distributed and caching agent
      alias :master :new
      # make_cached :get, :method=>:new
      # make_distributed :master, :method=>:get, :drb_urls=>['druby://localhost:9001']
    end
    
    def fib(n)
      # puts "#{self}\#fib"
      (0..1)===n ? 1 : fib(n-1) + fib(n-2)
    end
      
    make_cached :fib
    make_distributed :fib, 
      :urls=>('druby://localhost:9002'..'druby://localhost:9003')
    
    def initialize
      @count = 0
    end
    
    def hi
      @count += 1
      puts @count
      # puts "I distribute methods #{self.__distributor.keys} on port #{self.drb_port}"
    end
  end
  # Ruby instance 1:
  m = FibonacciMaster.new
  puts m.fib(10)
  puts m.fib(10)
  m = FibonacciMaster.new
  puts m.fib(13)
  puts m.fib(14)
  STDOUT.flush
  DBb.thread.join if ARGV.include?('server')
end
