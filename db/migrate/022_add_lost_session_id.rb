class AddLostSessionId < ActiveRecord::Migration[6.0]
  def self.up
    add_column :losts, :session_id, :string
    add_index :losts, :session_id
  end

  def self.down
    remove_column :losts, :session_id
  end
end
