# :main: make_cached

$:.unshift File.dirname(__FILE__) 
=begin rdoc 
=end
require 'hash_heap'

class HeapItemMinWeight < HeapItem  #:nodoc:
  def <=(a)
    self.v.weight >= a.v.weight
  end
end

# Redefine method update_weight in module +WrapperMixin+ if you want 
# change old&unpopular values decaching behaivor.
module WrapperMixin
  attr_accessor :idx #:nodoc:
  #time the value cached was last accessed at
  attr_accessor :accessed_at 
  attr_accessor :gap, :weight, :decay_time #:nodoc:
  #time the value was cached at
  attr_accessor :cached_at 
  def update_weight
    tdiff = (t=Time.now) - @accessed_at
    tdiff = 10 * @decay_time if tdiff > 10*@decay_time
    r = ( 0.4 + 0.6 * (2.0**(-tdiff/@decay_time)) )
    @gap = @gap * r  + tdiff * (1 - r)
    @weight = t - 0.0*@gap
    @accessed_at = t
    @weight
  end
end
 
class Wrapper #:nodoc:
  include WrapperMixin
  attr_accessor :value
  def initialize(o) 
    @value = o
  end
end

def wrap(o, no_wrap=false) #:nodoc:
  unless o.is_a?(Wrapper)
  if !no_wrap || [NilClass,FalseClass,TrueClass,Fixnum,Bignum,Symbol,Float].include?(o.class)
     Wrapper.new(o)
  else
    class <<o
      include WrapperMixin
    end
    o
  end
  end
end

def unwrap(o) #:nodoc:
  if o.is_a?(Wrapper)
    o.value
  else
    o
  end
end

=begin rdoc 
This method provides functionality related to the caching method results.

Method +make_cached+ allows to create cached versions of existing methods.
It should be used within Module or Class context.

:call-seq: 
  make_cached method                          -> cache
  make_cached method, options                 -> cache
  
Example:
  make_cached :hello, :method=>:hi, :timeout=>1.hour, :limit=>100
      
+method+:: name  of the new method with caching (Symbol)
+options+:: 
  hash of options
  [:method] name of the original method (Symbol)
  [:limit]  maximum cache size (Integer).  Defaults to 1000
  [:if] an additional restriction on the values you're to cache.  +Proc+ that blocks caching if it's true for the result of evaluating +method+
  [:timeout] life time  of cached value in seconds (Float)
  [:cache_in] scope of cache, allowed values are :object (default), :class, :global

If option :method is ommitted or its value is equal to +method+ then method +method+ is redefined.
It is usefull when method has recursive calls.


Method +make_cached+ should be invoked in the context of a
module or a class. In the latter case one instance starts caching
the method results and all other instances use them.


Example 1:
  module Fib
    def fib(n)
      if n == 0 || n == 1
        1
      else
        fib(n-1)+fib(n-2)
      end
    end
    make_cached :fib
  end
  include Fib
  puts fib(1000) #  fairly fast
  
Example 2:
  class Track << ActiveRecord:Base
    class <<self
      make_cached :get, :find, :limit=>100, :timeout=>1.hour
    end
  end
  # Now class Track is caching its instances
  Track.get(1) # db queries
  Track.get(1) # no db queries
  
If result has virtual class then it's enhanced by method +accessed_at+.
One can manipulate caching logic by changing this value:

 Track.get(1).accessed_at += 2.hours

This will make the object Track.get(1) cached at least for 2 hours.

=end
def make_cached(cached_method, options = {}) 
  options = options.dup
  orig_method = (options.delete(:method) || cached_method).to_sym
  cached_method = cached_method.to_sym
  limit = options.delete(:limit) || 1000
  timeout = options.delete(:expire_in) || options.delete(:timeout) || options.delete(:recache_after) 
  decay_time = options.delete(:decay_time) || 3.0
  no_wrap = options.delete(:no_wrap) || false
  cache_in = options.delete(:cache_in) || :object
  cache_if = options.delete(:cache_if)
  recache_if = options.delete(:recache_if)

  # raise ArgumentError, "Bad keys in parameters: #{options.keys.join("\n")}"
  
  if orig_method == cached_method
    orig_method = "orig_#{cached_method}".to_sym
    self.class_eval "alias :#{orig_method} :#{cached_method}"
  end

  enhance_object = lambda do |object| 
    object = wrap(object, no_wrap) unless object.is_a?(Wrapper)
    object.cached_at = object.accessed_at = Time.now
    object.decay_time = decay_time
    object.gap = 0.2*decay_time
    object.weight = object.accessed_at - 1.8*object.decay_time
    #~ puts "put[#{args}, #{object.inspect}]"
    object
  end

  eval_and_enhance_result = lambda do |o,args|
    object = o.send(orig_method, *args)
    enhance_object[object]
  end
 
  heap_klass = Class.new(HashHeap)

  heap_klass.send(:define_method, :[]=) do |args,object|
    o = object
    object = enhance_object[object] unless object.is_a?(Wrapper)
    super(args,object)
    o
  end

  # Caching #{cached_method} in #{cache_in}
  cache = nil
  case cache_in
  when :class
    @@__cache ||= {}
    cache = @@__cache[cached_method] ||= heap_klass.new(nil, HeapItemMinWeight)
    find_cache = lambda do |o,_cached_method|
      cache
    end
  when :global
    $__cache ||= {}
    cache = $__cache[cached_method] ||= heap_klass.new(nil, HeapItemMinWeight)
    find_cache = lambda do |o,_cached_method|
      cache
    end
  when :object
    def __cache #:nodoc:
      @__cache ||= {}
    end
    find_cache = lambda do |o,_cached_method|
      o.__cache[_cached_method] ||=  heap_klass.new(nil, HeapItemMinWeight)
    end
    cache_name = cached_method.to_s + '_cache'
    cache_name_var = '@' + cache_name
    self.send(:define_method, cache_name) do
      if c = instance_variable_get(cache_name_var)
        c
      else
        instance_variable_set(cache_name_var,
          __cache[cached_method] ||= find_cache[self, cached_method]
        )
      end
    end
  else
    raise ArgumentError, "Bad value '#{cache_in}' for parameter :cache_in"
  end

  self.send(:define_method, cached_method) do |*args|
    cache = find_cache[self, cached_method]
    arg = (args.size == 1 and !args.first.is_a?(Hash)) ? args.first : args

    object = cache[arg]

    if object && (
      (timeout &&  object.cached_at + timeout < Time.now) ||
      (recache_if && recache_if[self, arg, unwrap(object)])
    ) then
      cache.delete(arg)
      object = nil
    end

    # TODO: check why this does not work
    object ||= eval_and_enhance_result[self, arg]

    if !cache_if || cache_if[self, arg, unwrap(object)]
      if cache.size >= limit
        v = cache.extract 
      end
      cache[arg] ||= object
      object.update_weight
      cache.update(arg)
    end

    unwrap(object)
  end
  cache
end

# :enddoc:
if $0 == __FILE__

  # :stopdoc:
  require 'test/unit'

  # define artificial time for calculating cache-related gain in spead
  # (see test_optimal)
  class Time #:nodoc:
    @@time = 0.0
    @@cpu_time = 0.0
    class <<self
      def now; @@time; end
      def now=(t); @@time=t; end
      def cpu_time; @@cpu_time; end
      def cpu_time=(t); @@cpu_time=t; end
      def sleep(n);  @@time += n; end
      def work(n);  @@time += n; @@cpu_time += n; end
    end
  end
      
  class Track #:nodoc:
    attr_accessor :id, :created_at
    def initialize(id)
      @id = id
      @created_at = Time.now
    end
    class << self
      def find(i)
        Time.work 1.0
        Track.new(i)
      end
      make_cached :get_nowrap, :method=>:find, :limit=>50, :timeout=>100000, :cache_in=>:object, :no_wrap=>true
      make_cached :get, :method=>:find, :limit=>50, :timeout=>100000, 
          :cache_in=>:object
    end

  end
    

  class Xxx
    attr_accessor :a
    def initialize(a)
      @a = a
    end
    
    def i(i)
      return nil if i == 0
      i * @a
    end

    def j(i)
      i * @a
    end
    make_cached :i, :cache_in=>:object, :cache_if => lambda{|klass,args,value| !value.nil?}
    make_cached :j, :cache_in=>:class
  end

  module Fib #:nodoc:
    def fib(n)
      if n == 0 || n == 1
        1
      else
        fib(n-1) + fib(n-2)
      end
    end
    make_cached :fib
  end
  include Fib
  
  class TestMakeCached < Test::Unit::TestCase #:nodoc:
    def test_fib
      a = 0
      201.times {|i| fib(i) }
      th = Thread.new {
        a = fib(300) #  fairy fast
      }
      th.join(3.5)
      assert_equal(589801, a % 1000000)
    end
  
    def test_optimum
      queries = []
      
      srand(12345)
      lookers = Array.new(1000) {|id| [id, rand(1000), (1+rand(15)*(1+rand)).to_i, 1+7*rand*rand]} 
      
      lookers.each {|id, start_time, n, gap|
        n.times {|i|
          queries << [start_time + i*gap + gap*rand, id ]
        }
      }
      res = ""
      res << "Size = #{queries.size}\n"
      res << "start_time=#{Time.cpu_time}\n"
      Time.now = queries[0]
      queries.sort.each do |time, id|
        Time.now = time
        Track.get(id)
      end
      res << "end_time=#{Time.cpu_time}\n"
      assert(Time.cpu_time < 1050)
      res
    end
   

    def test_timeout
      # Track.cache.clear
      tr = Track.get_nowrap(11111111)
      t = Time.now
      assert_equal(t, tr.cached_at)
      Time.sleep(1)
      tr = Track.get_nowrap(11111111)
      assert_equal(t, tr.cached_at)
      Time.sleep(100001)
      tr = Track.get_nowrap(11111111)
      assert_not_equal(tr.cached_at, t)
    end

    def test_manual_cache_change
      # Track.cache.clear
      Track.get_cache[0] = 0
      tr1 = Track.get(1)
      tr2 = Track.get(112)
      Track.get_cache[112] = 1
      Track.get_cache[1] = nil
      
      assert_equal(1, Track.get(112))
      assert_equal(nil, Track.get(1))
      assert_equal(0, Track.get(0))

      Track.get_nowrap_cache[0] = 0
      tr1 = Track.get_nowrap(1)
      tr2 = Track.get_nowrap(112)
      Track.get_nowrap_cache[112] = 1
      Track.get_nowrap_cache[1] = nil
      
      assert_equal(1, Track.get_nowrap(112))
      assert_equal(nil, Track.get_nowrap(1))
      assert_equal(0, Track.get_nowrap(0))
    end

    def test_cache_scope
      identity  = Xxx.new(1)
      doubler   = Xxx.new(2)
      
      assert(identity.__cache.object_id != doubler.__cache.object_id)


      assert_equal(10, identity.i(10))
      assert_equal(20, doubler.i(10))
      assert_equal(2, doubler.i(1))
      assert_equal(1, identity.i(1))

      assert_equal(10, identity.j(10))
      assert_equal(10, doubler.j(10))
      assert_equal(2, doubler.j(1))
      assert_equal(2, identity.j(1))
    end

    def test_cache_if
      x = Xxx.new(10)
      x.i(5)
      x.i(0)
      assert_not_equal(nil, x.i_cache[5])
      assert_equal(nil, x.i_cache[0])
    end
  end
end




