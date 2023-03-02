class As::RolesPermissionController < ApplicationController
  layout 'expert'
  require_permission :permissions

  # active_scaffold :roles_permission do |config|
  #   config.columns = [:role, :permission]
  # end
end
