module PeopleHelper
  def people_cfg
    @cfg ||= APP_CONFIG['people']||{}
  end

  def regions_cfg
    @@regions ||= YAML.load_file(File.join(RAILS_ROOT, 'config', 'regions.yml')) 
  end

  def people_statuses
    @people_statuses ||= (people_cfg['statuses']||{})
  end
  
  def person_status_tag(person)
    "<span class=\"status_#{person.status}\">" + people_statuses[person.status] + "</span>"
  end

  def status_filter_field(status)
    people_statuses[status.to_i] || 'неизв.'
  end

  def recent_tag(person)
    if person.recent
      '<div class="recent_tag">горячий след</div>'
    end
  end
end

