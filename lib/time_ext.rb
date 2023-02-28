class Integer
  def to_hsecs
    x = self % 20
    if (5..20) === x || (5..10) === x%10 || 0 == x%10
      self.to_s + " секунд"
    elsif x==1
      self.to_s + " секунду"
    else
      self.to_s + " секунды"
    end
  end

  def to_hmins
    x = self % 20
    if (5..20) === x || (5..10) === x%10 || 0 == x%10
      self.to_s + " минут"
    elsif x==1
      self.to_s + " минуту"
    else
      self.to_s + " минуты"
    end
  end

  def to_hhours
    x = self % 20
    if (5..20) === x || (5..10) === x%10 || 0 == x%10
      self.to_s + " часов"
    elsif x==1
      self.to_s + " час"
    else
      self.to_s + " часа"
    end
  end
end

class Hash
  def to_date
    if year = self[:year] || self['year'] and
      month = self[:month] || self['month'] and
      day = self[:day] || self['day'] then
      Date.new(year, month, day)
    else
      raise ArgumentError, "Hash should contain :year, :month and :day keys"
    end
  end
end

class Time
  def to_yyyy_mm_dd
    "%04d.%02d.%02d" % [year, month, day]
  end

  def to_yyyy_mm_dd_time
     to_yyyy_mm_dd + (" %02d:%02d" % [hour,min])
  end

  def to_human
    a,b = self, Time.now
    past=true;
    if a > b
      a,b = b,a
      past = false
    end
    x = (b-a).to_i

    ans=case x
        when (0..60)
          x.to_i.to_hsecs
        when (60..3600)
          (x/60).to_hmins + ((x%60!=0)? " " + (x%60).to_hsecs : "")
        when (3600..36000*40)
          x/=60
          (x/60).to_hhours + ((x%60!=0)? " " + (x%60).to_hmins : "")
        else
          x/=60*60
          x.to_hhours
        end
    if past
      ans += " назад"
    else
      ans = "через " + ans
    end
    ans
  end

  def self.parse_ext(s)
    Time.parse(s)
  rescue ArgumentError
    return nil if s.blank?
    case s
    when 'now'
      Time.now
    when /^(\d\d\d\d)\.(\d\d)\.(\d\d)\s+(\d\d):(\d\d)$/
      Time.utc($1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i)
    when /^(\d\d\d\d)\.(\d?\d)\.(\d?\d)$/
      Time.utc($1.to_i, $2.to_i, $3.to_i)
    when /^(\d?\d).(\d?\d)$/
      Time.utc(Time.now.year, $1.to_i, $2.to_i)
    else
      nil
    end
  end
end

