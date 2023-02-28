class CreateTagsTopic < ActiveRecord::Migration[6.0]
  def self.up
    create_table :tags_topics do |t|
      t.integer :tag_id
      t.integer :topic_id
      t.integer :number, :null => false, :default => 0

      t.timestamps
    end
    add_index :tags_topics, :tag_id
    add_index :tags_topics, :topic_id
  end

  def self.down
    drop_table :tags_topics
  end
end
