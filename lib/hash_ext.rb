class Hash
  def first
    res=[nil,nil]
    self.each do |k,v|
      res = [k,v]
      break
    end
    return res
  end

  def without(*keys)
    keys.flatten!
    h = self.dup
    keys.each do |k|
      h.delete(k)
    end
    h
  end
  alias :except :without

  def key_with_min_value
    k_m,v_m = self.first
    self.each do |k,v|
      k_m,v_m = k,v if v < v_m
    end
    [k_m,v_m]
  end

  def extract_min_value
    unless empty?
      k,v = key_with_min_value
      [k, delete(k)]
    else
      nil
    end
  end

  def key_with_max_value
    k_m,v_m = self.first
    self.each do |k,v|
      k_m,v_m = k,v if v < v_m
    end
    [k_m,v_m]
  end

  def extract_max_value
    unless empty?
      k,v = key_with_max_value
      [k, delete(k)]
    else
      nil
    end
  end


  def subhash_with_max_values(n)
    return self if size <= n
    res = {}
    self.to_a.sort_by{|k,v| v}.last_n(n).each {|k,v|
      res[k]=v
    }
    res
  end

  def keys_and_values_to_s
    self.each {|k,v|
      (self.delete(k) and next) if (v.nil? or k.nil?)
      self[k.to_s] = self.delete(k).to_s unless (k.is_a?(String) && v.is_a?(String))
    }
  end

  def flip(h)
    g = self.dup
    h.each_key do |k|
      if h[k] && self[k] != h[k] && h[k] != ''
        g[k] = h[k]
      else
        g.delete(k)
      end
    end
    g
  end

  alias :flip_update :flip

  def project(*ary)
    ary = ary.first if ary.size == 1 && ary.first.is_a?(Array)
    ary.inject({}){|h,x| h[x] = self[x] if self.has_key?(x); h}
  end
end

