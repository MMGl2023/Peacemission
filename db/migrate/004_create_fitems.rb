class CreateFitems < ActiveRecord::Migration
  def self.up
    create_table :fitems, :force=>true do |t|
      t.string :name
      t.string :original_filename
      t.string :content_type
      t.string :comment
      t.integer :user_id
      t.string :ext

      t.timestamps
    end

    [:name, :original_filename, :content_type, :comment, :user_id, :ext].each do |f|
      add_index :fitems, f
    end
  end

  def self.down
    drop_table :fitems
  end
end
