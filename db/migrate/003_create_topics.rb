$:.unshift File.dirname(__FILE__)
require 'migration_ext'

class CreateTopics < ActiveRecord::Migration
  def self.up
    create_table :topics, :force=>true do |t|
      t.string :name
      t.string :title
      t.text :content, :summary
      t.string :engine, :author
      t.datetime :published_at
      t.string :section

      t.timestamps
    end
    [:name, :title, :author, :published_at, :section].each do |f|
      ensure_add_index :topics, f
    end
    
    add_text_index :topics, :content, :length=>128

    # execute " ALTER TABLE `topics` ADD INDEX `index_topics_on_content` ( `content` ( 128 ) )"
  end

  def self.down
    drop_table :topics
  end
end
