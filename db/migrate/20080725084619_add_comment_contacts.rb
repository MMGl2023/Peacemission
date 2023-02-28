class AddCommentContacts < ActiveRecord::Migration[6.0]
  def self.up
    add_column :comments, :contacts, :string, :limit => 256
    add_index :comments, :contacts
  end

  def self.down
    remove_column :comments, :contacts
  end
end
