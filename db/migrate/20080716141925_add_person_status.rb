class AddPersonStatus < ActiveRecord::Migration[6.0]
  def self.up
    add_column :people, :status, :integer, :default => 0
    add_index :people, :status
  end

  def self.down
    remove_column :people, :status
  end
end
