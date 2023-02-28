class CreateTopicRevisions < ActiveRecord::Migration[6.0]
  def self.up
    # drop_table :topic_revisions

    create_table :topic_revisions, :force=>true do |t|
      t.string :name
      t.text :topic_data
      t.integer :rev
      t.integer :topic_id
      t.integer :rev_type, :default => 0 # 0 - full topic dump, 1`- diff with next rev
      t.string :comment
      t.integer :author_id

      t.timestamps
    end

    add_index :topic_revisions, [:topic_id, :rev]
    add_index :topic_revisions, :name

    Topic.all.each do |topic|
      TopicRevision.create(
        :name => topic.name,
        :topic_id => topic.id,
        :topic_data => TopicRevision.topic_data(topic),
        :rev => 1
      )
    end
  end

  def self.down
    drop_table :topic_revisions
  end
end
