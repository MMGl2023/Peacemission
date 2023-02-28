class AddTopicTagsText < ActiveRecord::Migration[6.0]
  def self.up
    add_column :topics, :tags_text, :text
  end

  def self.down
    remove_column :topics, :tags_text
  end
end
