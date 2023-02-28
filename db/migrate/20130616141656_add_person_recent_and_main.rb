class AddPersonRecentAndMain < ActiveRecord::Migration[6.0]
  def self.up
    add_column :people, :recent, :boolean, :default => false
    add_column :people, :main,   :boolean, :default => true
    add_index :people, [:recent, :disappear_region]
    add_index :people, [:main, :disappear_region]
  end

  def self.down
    remove_index :people, [:main, :disappear_region]
    remove_index :people, [:recent, :disappear_region]
    remove_column :people, :main
    remove_column :people, :recent
  end
end
