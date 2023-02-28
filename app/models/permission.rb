class Permission < ActiveRecord::Base
  validates_presence_of :permission
  has_many :roles_permissions, :dependent => :destroy
  has_many :roles, :through => :roles_permissions

  def to_label
    self.permission
  end
end
