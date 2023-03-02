class As::PermissionController < ApplicationController
  layout 'expert'
  require_permission :permissions

  # active_scaffold :permission do |config|
  #   config.columns = [:permission, :description, :roles_permissions ]
  #   config.columns[:roles_permissions].label ="Roles"
  # end
end
