class AddLostSessionId < ActiveRecord::Migration
  def self.up
    add_column :losts, :session_id, :string
    add_index :losts, :session_id
  end

  def self.down
    remove_column :losts, :session_id
  end
end
