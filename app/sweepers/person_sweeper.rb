class PersonSweeper < ActionController::Caching::Sweeper
  observe Person

  # If our sweeper detects that a Person was created call this
  def after_save(person)
    expire_cache_for(person)
  end
  
  # If our sweeper detects that a Person was deleted call this
  def after_destroy(person)
    expire_cache_for(person)
  end
          
  private
  def expire_cache_for(person)
    # expire_fragment( %r{people/index/.*} )
    `setsid rm -rf tmp/cache/views/*rozysk.org*/people/index/*`
    
    # expire_fragment( %r{people/#{person.id}/.*} )
    `setsid rm -rf tmp/cache/views/*rozysk.org*/people/#{person.id}/*`
  end

end

