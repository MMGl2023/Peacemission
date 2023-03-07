class RolesUser < ActiveRecord::Base
	belongs_to :user, optional: true
	belongs_to :role, optional: true
  def to_label
    self.role.role + ':' + self.user.login rescue "#{role_id}:#{user_id}"
  end
end
