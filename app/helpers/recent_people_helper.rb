module RecentPeopleHelper
  def recent_people_cfg
    @cfg ||= APP_CONFIG['recent_people'] || {}
  end

  def regions_cfg
    @@regions ||= YAML.load_file(File.join(RAILS_ROOT, 'config', 'regions.yml'))
  end

  def recent_people_statuses
    @people_statuses ||= (recent_people_cfg['statuses'] || {})
  end

  def person_status_tag(recent_person)
    raw("<span class=\"status_#{recent_person.status}\">" + recent_people_statuses[recent_person.status] + "</span>")
  end

  def status_filter_field(status)
    raw(recent_people_statuses[status.to_i] || 'неизв.')
  end

  def recent_tag(recent_person)
    raw('<div class="recent_tag">горячий след</div>')
  end
end

