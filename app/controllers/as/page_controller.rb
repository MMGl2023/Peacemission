class As::PageController < ApplicationController
  layout 'expert'

  require_permission :pages
  
  active_scaffold :page do |config|
    # config.columns = [ ]
    # config.show.columns << [ ]
  end

  def new_or_edit
    p = Page.find_or_create_by_name(params[:name])
    redirect_to :action=>'edit', :id=>p.id
  end
end
