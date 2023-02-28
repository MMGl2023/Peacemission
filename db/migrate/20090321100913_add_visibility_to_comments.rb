class AddVisibilityToComments < ActiveRecord::Migration[6.0]
  def self.up
    # 0 - for all
    # 1 - for authenticated users
    add_column :comments, :visibility, :integer
    add_index :comments, [:visibility, :created_at]
  end

  def self.down
    remove_column :comments, :visibility
  end
end
