class AddShowFlagsForTopics < ActiveRecord::Migration[6.0]
  @@fields = [
    ['show_title', true],
    ['show_published_at', false],
    ['show_author', false],
    ['justified', true]
  ]
  # remove_column :topics, :show_title
  def self.up
    @@fields.each do |f,d|
      add_column :topics, f, :boolean, :default => d
    end
  end

  def self.down
    @@fields.each do |f,d|
      remove_column :topics, f
    end
  end
end
