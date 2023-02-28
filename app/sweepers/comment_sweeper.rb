class CommentSweeper < ActionController::Caching::Sweeper
  observe Comment

  # If our sweeper detects that a Topic was created call this
  def after_create(comment)
    expire_cache_for(comment)
  end
  
  # If our sweeper detects that a Topic was updated call this
  def after_update(comment)
    expire_cache_for(comment)
  end
  
  # If our sweeper detects that a Topic was deleted call this
  def after_destroy(comment)
    expire_cache_for(comment)
  end
  
  private
  def expire_cache_for(comment)
    root = comment.root
    case root.obj_type
    when 'Topic'
      name = root.obj.name
      if name
        File.unlink( File.join(RAILS_ROOT, 'public', 'i', "#{name}.html") ) rescue nil
      end
    end
  end
end

