class As::FitemController < ApplicationController
  layout 'expert'

  require_permission :fitems

  active_scaffold :fitem do |config|
    config.columns << :url
    # config.columns = [:fhash, filename, :content_type]
    # config.show.columns << [:created_at, :user, :fitems]
  end
end
