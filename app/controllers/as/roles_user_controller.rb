class As::RolesUserController < ApplicationController
  layout 'expert'
  require_permission :permissions

  # active_scaffold :roles_user do |config|
  #   config.columns = [:role, :user]
  # end
end
