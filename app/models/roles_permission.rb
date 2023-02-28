class RolesPermission < ActiveRecord::Base
  belongs_to :permission
  belongs_to :role
  def to_label
    self.role.role + ":" + self.permission.permission
  end
end
