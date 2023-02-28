class AddPersonStatus < ActiveRecord::Migration
  def self.up
    add_column :people, :status, :integer, :limit => 11, :default => 0
    add_index :people, :status
  end

  def self.down
    remove_column :people, :status
  end
end
