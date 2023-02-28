class AddPersonLostId < ActiveRecord::Migration
  def self.up
    add_column :people, :lost_id, :integer
    add_index :people, :lost_id
  end

  def self.down
    remove_column :people, :lost_id
  end
end
