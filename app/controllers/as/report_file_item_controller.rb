class As::ReportFitemController < ApplicationController
  layout 'expert'

  require_permission :reports

  active_scaffold :report_file_item do |config|
    config.columns << :url
    # config.columns = [:fhash, filename, :content_type]
    # config.show.columns << [:created_at, :user, :fitems]
  end
end
