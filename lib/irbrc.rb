def Object.method_added(method)
  return super(method) unless method == :helper
  (class<<self;self;end).send(:remove_method, :method_added)

  def helper(*helper_names)
    returning $helper_proxy ||= Object.new do |helper|
      helper_names.each { |h| helper.extend "#{h}_helper".classify.constantize }
    end
  end

  helper.instance_variable_set("@controller", ActionController::Integration::Session.new)

  def helper.method_missing(method, *args, &block)
    @controller.send(method, *args, &block) if @controller && method.to_s =~ /_path$|_url$/
  end

  helper :application rescue nil
end if ENV['RAILS_ENV']

ANSI_BOLD       = "\033[1m"
ANSI_RESET      = "\033[0m"
ANSI_LGRAY    = "\033[0;37m"
ANSI_GRAY     = "\033[1;30m"

def pm(obj, *options) # Print methods
  methods = obj.methods
  methods -= Object.methods unless options.include? :more
  filter = options.select {|opt| opt.kind_of? Regexp}.first
  methods = methods.select {|name| name =~ filter} if filter

  data = methods.sort.collect do |name|
    method = obj.method(name)
    if method.arity == 0
      args = "()"
    elsif method.arity > 0
      n = method.arity
      args = "(" + (1..n).collect {|i| "arg#{i}"}.join(", ") + ")"
    elsif method.arity < 0
      n = -method.arity
      args = "(" + (1..n).collect {|i| "arg#{i}"}.join(", ") + ", ...)"
    end
    klass = $1 if method.inspect =~ /Method: (.*?)#/
    [name, args, klass]
  end
  max_name = data.collect {|item| item[0].size}.max
  max_args = data.collect {|item| item[1].size}.max
  data.each do |item| 
    print " #{ANSI_BOLD}#{item[0].rjust(max_name)}#{ANSI_RESET}"
    print "#{ANSI_GRAY}#{item[1].ljust(max_args)}#{ANSI_RESET}"
    print "   #{ANSI_LGRAY}#{item[2]}#{ANSI_RESET}\n"
  end
  data.size
end
