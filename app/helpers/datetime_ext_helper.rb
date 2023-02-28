unless defined? MONTHS
  MONTHS = %w(январь февраль март апрель май июнь июль август сентябрь октябрь ноябрь декабрь)
end

module ExtractDateTime
  def extract_date(field_name, options)
    f = (1..3).map { |t| options.delete("#{field_name}(#{t}i)") }
    options[field_name] = f.any?(&:blank?) ? nil : Date.civil(*f.map(&:to_i))
  end

  def extract_datetime(field_name, options)
    f = (1..6).map { |t| options.delete("#{field_name}(#{t}i)") }
    options[field_name] = f.any?(&:blank?) ? nil : Time.local(*f.map(&:to_i))
  end

  # is used in pair with select_date_year
  def extract_date_year(date_f, year_f, options)
    f = fuzzy_date_field_names(date_f).map { |t| options.delete(t) }
    options[year_f] = f[0]
    options[date_f] = f.any?(&:blank?) ? nil : Date.new(*f.map(&:to_i))
  end

  # is used in pair with select_fuzzy_date
  def extract_fuzzy_date(*fields)
    options = extract_options(fields)
    populate_fuzzy_fields(fields)
    date_f = fields.shift
    f = fuzzy_date_field_names(date_f).map { |t| options.delete(t) }
    fields.each_with_index { |field, idx|
      options[field] = f[idx]
    }
    options[date_f] = f.any?(&:blank?) ? nil : Date.new(*f.map(&:to_i))

    puts options
  end
end

module DatetimeExtHelper
  def time_s(time_at, format = "%Y.%m.%d %H:%M")
    time_at ? TzTime.zone.strftime(format, time_at.utc) : ''
  end

  def datetime_s(time_at, format = "%Y.%m.%d %H:%M")
    time_at ? TzTime.zone.strftime(format, time_at.utc) : ''
  end

  def date_s(time_at, format = "%Y.%m.%d")
    time_at = time_at.to_time if time_at.is_a?(Date) # FIXME
    if time_at.is_a?(Time)
      TzTime.zone.strftime(format, time_at.utc)
    elsif time_at.is_a?(Date)
      "%4d.%02d.%02d" % [time_at.year, time_at.month, time_at.day]
    else
      ''
    end
  end

  def fuzzy_date_field_names(date_f)
    %w(year month day).map! { |f| date_f.to_s + "(#{f})" }
  end

  def populate_fuzzy_fields(fields, o = nil)
    if fields.size == 1
      date_fld = fields.first.to_s
      if date_fld =~ /_on$/
        year_fld = date_fld.sub(/_on$/, '_on_year')
        month_fld = date_fld.sub(/_on$/, '_on_month')
      elsif date_fld =~ /_date$/
        year_fld = date_fld.sub(/date$/, 'year')
        month_fld = date_fld.sub(/date$/, 'month')
      else
        return
      end
      if o.nil? || o.respond_to?(year_fld)
        fields << year_fld
        if o.nil? || o.respond_to?(month_fld)
          fields << month_fld
        end
      end
    end
  end

  def date_year_s(obj, date_f, year_f)
    obj[date_f].blank? ? obj[year_f].to_s : date_s(obj[date_f])
  end

  def fuzzy_date_s(obj, *fields)
    options = extract_options(fields) || {}
    populate_fuzzy_fields(fields, obj)
    date_f = fields.shift
    options[:format] ||= [options[:reverse] ? "%d.%m.%Y" : "%Y.%m.%d", "%04d", "%02d", "%02d"]
    noval = (options[:undef] ||= '*')
    join_by = (options[:join_by] ||= '.')
    links = [:link_year, :link_month, :link_day]
    unless obj[date_f].blank? || links.any? { |l| options.has_key?(l) }
      raw(date_s(obj[date_f], options[:format].first))
    else
      links = [:link_year, :link_month, :link_day]
      values = fields.map { |f| obj[f] }
      values << obj[date_f].day if obj[date_f] && fields.size == 2
      res = values.zip(options[:format][1..-1], links).map { |val, format, link|
        if val && format
          res = format.to_s % [val]
          # logger.info "LINK " + options[link].inspect
          res = link_to(res, *options[link]) if options[link]
          res
        else
          noval
        end
      }.take_while { |t| t != noval }
      res.reverse! if options[:reverse]
      raw(res.join(join_by))
    end
  end

  def select_date_year(obj, date_f, year_f, options = {})
    date = obj.send(date_f)
    year = obj.send(year_f)
    month = day = nil
    if date
      year = date.year
      month = date.month
      day = date.day
    end
    year ||= options.delete(:default_year)
    options[:include_blank] = true unless options.delete(:noblank)
    options[:use_month_numbers] = true unless options.delete(:use_month_names)
    options[:prefix] ||= obj.class.to_s.underscore

    res = fuzzy_date_field_names(date_f).zip(['year', 'month', 'day'], [year, month, day]).map { |field, name, value|
      send("select_" + name, value, options.merge(:field_name => field))
    }.join("\n")
    if obj.errors.on(date_f) || obj.errors.on(year_f)
      res = '<div class="fieldWithErrors"><div style="display:inline; background:none">' + res + '</div></div>'
    end
    res
  end

  def fuzzy_date_blank?(obj, *fields)
    populate_fuzzy_fields(fields, obj)
    fields.all? { |f| obj[f].blank? }
  end

  def select_fuzzy_date(obj, *fields)
    options = extract_options(fields)
    populate_fuzzy_fields(fields, obj)
    date, year, month, day = fields.map { |f| obj.send(f) }
    date_f = fields.first
    if date
      year = date.year
      month = date.month
      day = date.day
    end
    year ||= options.delete(:default_year)
    options[:include_blank] = true unless options.delete(:noblank)
    options[:use_month_numbers] = true unless options.delete(:use_month_names)
    options[:prefix] ||= obj.class.to_s.underscore

    res = fuzzy_date_field_names(date_f).zip(['year', 'month', 'day'], [year, month, day]).map { |field, name, value|
      send("select_" + name, value, options.merge(:field_name => field))
    }.join("\n")
    if fields.any? { |f| obj.errors.add(f) }
      res = '<div class="fieldWithErrors"><div style="display:inline; background:none">' + res + '</div></div>'
    end
    raw(res)
  end
end

module ManageFuzzyDate
  include DatetimeExtHelper

  def sync_fuzzy_date(*fields)
    pupulate_fuzzy_fields(fields)
    date_f = fields.shift
    unless date_f.blank?
      fields.zip([:year, :month, :day]).each do |field, name|
        self[fields] = date_f.send(name)
      end
    end
  end
end

ActionController::Base.class_eval do
  include DatetimeExtHelper
  include ExtractDateTime
end

ActionView::Base.class_eval do
  include DatetimeExtHelper
end

