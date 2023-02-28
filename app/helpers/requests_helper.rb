module RequestsHelper

  def requests_cfg
    @cfg ||= APP_CONFIG['requests']||{}
  end

  def request_types
    @request_types ||= (requests_cfg['request_types']||{})
  end

  def request_short_types
    @request_types ||= (requests_cfg['request_short_types']||{})
  end

  def request_statuses
    @request_statuses ||= (requests_cfg['request_statuses']||{})
  end

  def request_type_filter_field(v)
    request_short_types[v.to_i] || 'неизв.'
  end

end
