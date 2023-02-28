class AddTopicRev < ActiveRecord::Migration[6.0]
  def self.up
    add_column :topics, :rev, :integer
  end

  def self.down
    remove_column :topics, :rev
  end
end
