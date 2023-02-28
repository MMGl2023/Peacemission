class As::UserController < ApplicationController
  layout 'expert'

  require_permission :users
  
  active_scaffold :user do |config|
    config.columns = [:login, :name, :hidden, :roles_users]
    # friends, mood_radios, interests
    config.columns[:roles_users].label = "Roles"
    config.search.columns = [:login, :name, :email]
  end
end
