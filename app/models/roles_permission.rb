class RolesPermission < ActiveRecord::Base
  belongs_to :permission, optional: true
  belongs_to :role, optional: true
  def to_label
    self.role.role + ":" + self.permission.permission
  end
end
