class String
  RU_WORD = /[Р-пр-џ]+/
  RU_UP = ('Р'..'п').to_a.join
  RU_DOWN = ('р'..'џ').to_a.join
  def downcase_rus
    self.tr(RU_UP, RU_DOWN)
  end

  def to_yaml2
    res = self.dup
    if res.gsub!('"', '\\"') || res.index(':') || res.index("'")
       res = "\"#{res}\""
    end
    res
  end

  def hex_decode
    self.gsub(/\\x([\w\d][\w\d])/) { $1.to_i(16).chr }
  end

  def fingerprint
    s = self.dup
    s.gsub!(/\b\s*(and|&|'n')\s*\b/i, '&')
    s.gsub!(/[\s\(\)\-'"`\]\[,\.!;:|\/\\]+/i, ' ')
    s.downcase!
    s.strip!
    s
  end
    
  def similarity(str)
    s1 = self.fingerprint
    s2 = str.fingerprint
    s1,s2 = s2,s1 if s1.size > s2.size
    s1s = s1.size
    s2s = s2.size
    b1 = b2 = 0
   
    # find common prefix 
    while s1[b1] == s2[b1] && !s1[b1].nil? 
      b1 += 1
    end
    return 1.0 if s1s == s2s && b1==s1s
    return s1s.to_f/s2s if b1 == s1s
    v1 = s1s - 1
    v2 = s2s - 1
    hits = b2 = b1
    # and common suffix
    while s1[v1] == s2[v2] 
      v1 -= 1
      v2 -= 1
      hits += 1
    end
    while b1 <= v1 && b2 <= v2 
      (b1 += 1 and b2 += 1 and hits += 1 and next) if s1[b1] == s2[b2]
      (b2 += 1 and next) if s2[b2 + 1] == s1[b1]
      (b1 += 1 and next) if s2[b2] == s1[b1+1]
      if v1 - b1 > v2 - b2
        b1,b2,v1,v2,s1,s2 = b2,b1,v2,v1,s2,s1
      end
      b2 += 1
    end
    # p [s1s, s2s, missed, v2, b2, s1, s2]
    hits.to_f/[s1s,s2s].max
  end

  def %(hash)
    if hash.is_a?(Hash)
      s = self.dup
      hash.each do |key, value|
        s.gsub!(':'+key.to_s, value.to_s)
      end
      s
    else
      sprintf(self, *hash)
    end
  end

  from_letters = ""
  to_letters = ""

  $LETTERS_MAP = {192=>'A', 193=>'A', 194=>'A', 195=>'A', 196=>'A', 197=>'A', 198=>'?', 199=>'C', 200=>'E', 201=>'E', 202=>'E', 203=>'E', 204=>'I', 205=>'I', 206=>'I', 207=>'I', 208=>'?', 209=>'N', 210=>'O', 211=>'O', 212=>'O', 213=>'O', 214=>'O', 215=>'?', 216=>'O', 217=>'U', 218=>'U', 219=>'U', 220=>'U', 221=>'Y', 222=>'?', 223=>'?', 224=>'a', 225=>'a', 226=>'a', 227=>'a', 228=>'a', 229=>'a', 230=>'?', 231=>'c', 232=>'e', 233=>'e', 234=>'e', 235=>'e', 236=>'i', 237=>'i', 238=>'i', 239=>'i', 240=>'?', 241=>'n', 242=>'o', 243=>'o', 244=>'o', 245=>'o', 246=>'o', 247=>'?', 248=>'o', 249=>'u', 250=>'u', 251=>'u', 252=>'u', 253=>'y', 254=>'?', 255=>'y'}.each {|i,j|
    from_letters += i.chr
    to_letters += j
  }
  
  $FROM_LETTERS = from_letters
  $TO_LETTERS = to_letters

  def simplify_letters
    self.tr($FROM_LETTERS, $TO_LETTERS )
  end
  def simplify_letters!
    self.tr!($FROM_LETTERS, $TO_LETTERS )
  end

  def simplify_html_letters
    self.dup.simplify_html_letters!
  end

  def simplify_html_letters!
    self.simplify_letters!
    $LETTERS_MAP.each {|i,j|
      self.gsub!("&#" + i.to_s + ";", j)
    }
    self
  end

end

if __FILE__ == $0
  puts "Helllloolloo".similarity("Hello")
  puts "Helll  Oolloo".similarity("Hell  Oollloo")
end



