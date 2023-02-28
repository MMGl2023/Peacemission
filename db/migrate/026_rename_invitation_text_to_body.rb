class RenameInvitationTextToBody <ActiveRecord::Migration[6.0]
  def self.up
    rename_column :invitations, :text, :body
  end

  def self.down
    rename_column :invitations, :body, :text
  end
end
