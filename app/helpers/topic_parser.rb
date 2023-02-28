module TopicParser

  def self.included(klass)
    klass.extend ParseClassMethods
  end

  module ParseClassMethods
    attr_accessor :parsers

    def parsers
      @parsers ||= {}
    end

    def after_parse_callbacks
      @after_parse_callbacks ||= Hash.new {|h,k|  h[k]=[]; }
    end

    def basic_parser_for(macros, options={})
      regexp = /(#{macros.join('|')})[\{]([^\n]+?)[\}]/ 
      
      scanner = (
        options[:no_change] ?
          lambda {|text,block| text.scan(regexp){|m| block[$1, $2]}} :
          lambda {|text,block| text.gsub!(regexp){|m| block[$1, $2]}} 
      )

      {
        :macros  => macros,
        :scanner => scanner,
        :methods => macros.inject({}){|f, m| f[m] = 'parse_' + m.downcase; f}
      }
    end

    def register_macro_parser(method_name, macros, options={})
      parser = parsers[method_name] = basic_parser_for(macros, options)
      after = after_parse_callbacks[method_name]
      self.class_eval do
        define_method(method_name) do |topic, text|
          @parsing ||= {}
          begin
            unless @parsing[topic.id]
              @parsing[topic.id] = true
              topic.parse_errors = []
              expand_macros(topic, text, parser)
              after.each do |m|
                send(m, topic, text, parser)
              end
            end
          ensure
            @parsing[topic.id] = false
          end
          text
        end
      end
    end

    def after_parse(*methods)
      options =  methods.last.is_a?(Hash) ? methods.pop : {}
      methods_seqs = (options.has_key?(:for) ? 
        after_parse_callbacks.values_at(*options[:for]) : 
        after_parse_callbacks.values
      )
      methods_seqs.each {|seq| seq.push *methods }
    end
  end

  def expand_macros(topic, text, parser)
    topic.parse_errors = []
    parser[:scanner].call text, lambda {|macro, args|
      method = parser[:methods][macro]
      begin
        args = make_args(args)
        send(method, topic, *args)
      rescue => e
        error_info = [macro, method, args, e]
        topic.parse_errors << error_info
        error_text *error_info
      end
    }
  end

  def error_text(macro, method, args, e)
    # "<font color=\"red\">ERROR: #{macro}: #{e.message},#{e.backtrace.join("<br>")}</font>"
    "<font color=\"red\">ERROR: #{macro}: #{e.message}</font>"
  end

  def make_args(str)
    args, *options = str.split(/[\|;]/)
    args = YAML.load( '[' + args + ']' )
    options = options.inject({}) do |f, o|
      unless o.blank?
        k, v = o.split(/=/)
        k = k.strip.to_sym
        f[k] = (v ? v.gsub(/(^["']|["']$)/, '').strip : true)
      end
      f
    end
    args << options
  end
end
