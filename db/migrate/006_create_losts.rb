class CreateLosts < ActiveRecord::Migration
  def self.up
    create_table :losts, :force=>true do |t|
      t.string :full_name
      t.date :lost_on
      t.date :found_on
      t.integer :image_id
      t.integer :birth_year
      t.string :last_location
      t.text :details

      t.timestamps
    end
    [:full_name, :lost_on, :found_on, :image_id, :birth_year, :last_location].each do |f|
      add_index :losts, f
    end
    add_text_index :losts, :details
    # execute "ALTER TABLE `losts` ADD INDEX `index_losts_on_details` ( `details` ( 128 ) )"
  end

  def self.down
    drop_table :losts
  end
end
