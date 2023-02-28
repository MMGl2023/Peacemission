class As::TopicController < ApplicationController
  layout 'expert'

  require_permission :topics

  active_scaffold :topic do |config|
    # config.columns = [ ]
    # config.show.columns << [ ]
  end

  def new_or_edit
    p = Topic.find_or_create_by(name: params[:name])
    redirect_to action: 'edit', id: p.id
  end
end
