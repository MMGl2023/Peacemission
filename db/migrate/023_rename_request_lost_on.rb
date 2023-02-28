class RenameRequestLostOn < ActiveRecord::Migration
  def self.up
    rename_column :requests, :lost_on, :lost_on_date
    add_column :requests, :lost_on_year, :integer
    add_index :requests, [:lost_on_year, :lost_on_date]
  end

  def self.down
    remove_column :requests, :lost_on_year
    rename_column :requests, :lost_on_date, :lost_on
  end
end
