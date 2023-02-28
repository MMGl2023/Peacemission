class AddTopicLockInfo < ActiveRecord::Migration
  def self.up
    add_column :topics, :locked_by_id, :integer
    add_column :topics, :locked_at, :datetime
    add_index :topics, [:locked_by_id, :locked_at]
  end

  def self.down
    remove_column :topics, :locked_by_id
    remove_column :topics, :locked_at
  end
end
