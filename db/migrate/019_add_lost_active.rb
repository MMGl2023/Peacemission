$:.unshift File.dirname(__FILE__)
require  'migration_ext'

class AddLostActive < ActiveRecord::Migration
  def self.up
    add_column :losts, :active, :boolean, :defaut=>true
    ensure_add_index :losts, [:active, :created_at]
  end

  def self.down
    ensure_remove_index :losts, [:active, :created_at]
    remove_column :losts, :active
  end
end
