$:.unshift(File.dirname(__FILE__))
require 'string_ext'
require 'hash_ext'
require 'array_ext'
require 'active_record_ext'
require 'set_ext'
require 'time_ext'

def extract_options(ary)
  if ary.last && ary.last.is_a?(Hash)
    ary.pop
  else
    {}
  end
end

class Object
  # Sometime we need write chain of modifying/inspecting/printing debug messages/saving/..  methods :
  #   ary.tap(&:uniq!).tap(&:sort!).tap{|a| puts a.inspect }.tap{|a| file.write(a.dump)}...  
  # It does not create new array, while the following does create two more arrays:
  #   ary.uniq.sort
  # It does matter when array is large.
  def tap
    yield self
    self
  end
end

class Numeric
  def to_human_size
    case self
    when (0...901)
      "%d" % self.to_i
    when (901...900_001)
      "%.1f Kb" % (self/1_000.0)
    when (900_001...900_000_001)
      "%.1f Mb" % (self/1_000_000.0)
    else
      "%.1f Gb" % (self/10**9)
    end
  end
end

