class RolesUser < ActiveRecord::Base
	belongs_to :user
	belongs_to :role
  def to_label
    self.role.role + ':' + self.user.login rescue "#{role_id}:#{user_id}"
  end
end
