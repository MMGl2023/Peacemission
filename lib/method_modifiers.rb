# Method modifiers
#
# 1) befor, after and around wrappers
# 2) cache method  and share method 
#   NB:  moved to make_cached.rb and make_shared.rb
# 3) alias_method_chain variations
# 4) exception handlers
# 5) ...
#
module MethodModifiers

  def to_array(x)
    if x.respond_to?(:to_a)
      x.to_a
    else
      [x]
    end
  end

  def execute_it(smth, binding, *args)
    case smth
    when String
      eval smth, binding
    when Proc
      smth.call(type, *args)
    when Symbol
      send(smth, *args)
    else
      raise ArgumentError, "Not executable argument for execute_it"
    end
  end

  def exception_filter(new_method_name, options={})
    old_method_name = options[:method] || new_method_name
    if old_method_name.to_s == new_method_name
      old_method_name += 'orig'
      alias old_method_name new_method_name
    end


    define_method(new_method_name) do |*args|
      begin
        send(old_method_name, *args)
      rescue=>e
        call_info = "#{new_method_name}(#{args.join(",")})"
        options[:msg_filter] = to_array(options[:msg_filter])
        options[:obj_filter] = to_array(options[:obj_filter])
        if (options[:msg_filter] && options[:msg_filter].any?{|i| i ===  e.message} && type=:msg_filter) ||
            (options[:obj_filter] && options[:obj_filter].any?{|i| i ===  e} && type=:obj_filter)
          if options[:block]
            execute_it(options[:block], binding, type, *args)
          else 
            puts "Filter exception #{type} (#{e.message}): " + call_info 
          end
        else
          raise # re-raise exception
        end
      end
    end
  end
end

class Module
  include MethodModifiers
end

