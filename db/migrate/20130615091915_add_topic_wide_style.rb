class AddTopicWideStyle < ActiveRecord::Migration[6.0]
  def self.up
    add_column :topics, :wide_style, :boolean, :default => false
  end

  def self.down
    remove_column :topics, :wide_style
  end
end
