class RenameInvitationTextToBody <ActiveRecord::Migration
  def self.up
    rename_column :invitations, :text, :body
  end

  def self.down
    rename_column :invitations, :body, :text
  end
end
