class Set
  def blank?
    empty?
  end

  def first
    f = nil
    each {|x|  f = x;  break; }
    f
  end

  def last
    f = nil
    s = self.size
    each {|x| 
      (f = x && break) if s==1;
      s -= 1
    }
    f
  end
end

