class Role < ActiveRecord::Base
  has_many :roles_users
  has_many :users, :through => :roles_users
  has_many :roles_permissions, :dependent => :destroy
  has_many :permissions, :through => :roles_permissions
  validates_presence_of :role
  def to_label
    self.role
  end
end
