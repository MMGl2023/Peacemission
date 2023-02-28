class TopicSweeper < ActionController::Caching::Sweeper
  observe Topic

  # If our sweeper detects that a Topic was created call this
  def after_create(topic)
    expire_cache_for(topic)
  end
  
  # If our sweeper detects that a Topic was updated call this
  def after_update(topic)
    expire_cache_for(topic)
  end
  
  # If our sweeper detects that a Topic was deleted call this
  def after_destroy(topic)
    expire_cache_for(topic)
  end

  def before_update(topic)
    if topic.id
      topic.old_section = (t=Topic.find_by_id(topic.id, :select=>"section")) && t.section
    end
  end
  
  private
  def expire_cache_for(topic)
    if topic.section == 'news' or topic.old_section == 'news'
      # expire_action(:controller => 'topic', :action => 'news')
      `setsid rm -rf tmp/cache/views/rozysk.org/topics/news`
       File.unlink("public/news.html") rescue nil
    end

    if topic.content =~ /SET_VALUE\{\s*(\w+)/
      cmd = "setsid grep -r GET_VALUE_#{$1} public/i  tmp/cache/ | cut -f 1 -d ':' | sort -u | xargs -r rm -f"
      logger.info "CMD: '#{cmd}'"
      `#{cmd}`
    end

    # topic.name.gsub!(/(^\.|\s|\.\.)/,'')

    if topic.name == 'people_list'
      expire_fragment( %r(people/index/.*) )
    end
   
    if topic.name == 'lost_index'
      expire_fragment( %r(lost/.*) )
    end

    if topic.name == 'index'
      File.unlink("public/index.html") rescue nil
    end
    File.unlink("public/i/#{topic.name}.html") rescue nil
    #expire_page(:controller => 'topic', :action => 'i', :name => topic.name)
  end
end

