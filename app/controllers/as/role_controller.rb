class As::RoleController < ApplicationController
  layout 'expert'
  require_permission :permissions

  active_scaffold :role do |config|
    config.columns = [:role, :description, :roles_permissions, :roles_users]
    config.columns[:roles_users].label ="Users"
    config.columns[:roles_permissions].label ="Permissions"
  end
end
