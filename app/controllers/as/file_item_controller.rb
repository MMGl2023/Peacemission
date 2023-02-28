class As::FitemController < ApplicationController
  layout 'expert'

  require_permission :file_items
  
  active_scaffold :file_item do |config|
    config.columns << :url
    # config.columns = [:fhash, filename, :content_type]
    # config.show.columns << [:created_at, :user, :file_items]
  end
end
