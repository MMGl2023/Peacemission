class AddTopicTagsText < ActiveRecord::Migration
  def self.up
    add_column :topics, :tags_text, :text
  end

  def self.down
    remove_column :topics, :tags_text
  end
end
