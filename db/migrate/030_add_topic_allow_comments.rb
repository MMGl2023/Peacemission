class AddTopicAllowComments < ActiveRecord::Migration[6.0]
  def self.up
    add_column :topics, :allow_comments, :boolean, :default=>true, :null=>false
    Topic.all.each do |t|
      t.allow_comments = (t.section=='news')
      t.save
    end
  end

  def self.down
    remove_column :topics, :allow_comments
  end
end
