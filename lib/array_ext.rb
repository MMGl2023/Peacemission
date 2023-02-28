class Array
  def drop_while(&block)
    idx = (0...self.size).find { |i| !block[self[i]] }
    idx ? self[idx..-1] : []
  end

  def take_while(&block)
    idx = (0...self.size).find { |i| !block[self[i]] }
    idx ? self[0...idx] : self.dup
  end

  # def to_hash(fieldnames = [])
  #   h = {}
  #   fieldnames.each_with_index { |name, i| h[name] = self[i] }
  #   h.delete(nil)
  #   h
  # end

  def max_by(&block)
    sv = {}
    self.inject(self.first) { |a, x|
      if (sv[a] ||= block[a]) < (sv[x] ||= block[x])
        x
      else
        a
      end
    }
  end

  def min_by(&block)
    sv = {}
    self.inject(self.first) { |a, x|
      if (sv[x] ||= block[x]) < (sv[a] ||= block[a])
        x
      else
        a
      end
    }
  end

  def last_n(n)
    return [] if size == 0
    i = [self.size, n].min
    return self[-i..-1]
  end

  def to_set
    Set.new(self)
  end

  # spead version of uniq_by for sorted arrays
  def uniq_by_opt(&block)
    res = []
    return res if empty?
    res << first
    prev = block[res.last]
    each { |a|
      if prev != (n = block[a])
        res << a
        prev = n
      end
    }
    res
  end

  def uniq_by(&block)
    res = []
    done = {}
    each { |i|
      unless done[n = block[i]]
        res << i
        done[n] = true
      end
    }
    res
  end

end

