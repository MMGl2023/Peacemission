class LostSweeper < ActionController::Caching::Sweeper
  observe Lost

  # If our sweeper detects that a Lost was modified call this
  def after_save(lost)
    expire_cache_for(lost)
  end

  # If our sweeper detects that a Lost was created call this
  def after_create(lost)
    expire_cache_for(lost)
  end
   
  # If our sweeper detects that a Lost was deleted call this
  def after_destroy(lost)
    expire_cache_for(lost)
  end
          
  private
  def expire_cache_for(lost)
    `setsid rm -rf #{RAILS_ROOT}/tmp/cache/views/rozysk.org/losts/index`
    `setsid rm -rf #{RAILS_ROOT}/tmp/cache/views/rozysk.org/losts/#{lost.id}/`
  end
end

