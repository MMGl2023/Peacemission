class As::ReportController < ApplicationController
  layout 'expert'
  require_permission :reports

  active_scaffold :reports do |config|
    config.columns = [:report_type, :subject, :details, :os, :browser, :email]
    config.show.columns << [:created_at, :user, :fitems]
  end
end
