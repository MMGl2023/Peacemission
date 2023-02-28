class AddRequestSessionId < ActiveRecord::Migration[6.0]
  def self.up
    add_column :requests, :session_id, :string
    add_index :requests, :session_id
  end

  def self.down
    remove_column :requests, :session_id
  end
end
