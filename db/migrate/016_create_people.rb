$:.unshift File.dirname(__FILE__)
require 'migration_ext'

class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people, :force=>true do |t|
      t.string  :full_name
      t.date    :birth_date
      t.integer :birth_year
      t.string  :last_address
      t.date    :disappear_on
      t.integer  :disappear_year
      t.string  :disappear_region
      t.string  :disappear_location
      t.text    :remark
      t.integer :anket_n
      t.text    :orig_record 

      t.timestamps
    end
    
    [
      :full_name, :birth_year, :birth_date, :last_address, :anket_n,  
      [:full_name, :birth_year], :disappear_on, :disappear_year, :disappear_region,
      :disappear_location
    ].each do |f| 
      ensure_add_index :people, f
    end

    add_text_index :people, :remark
    add_text_index :people, :orig_record
    # execute(" ALTER TABLE `people` ADD INDEX `index_people_on_remark` ( `remark` ( 32 ) )")
    # execute(" ALTER TABLE `people` ADD INDEX `index_people_on_orig_record` ( `orig_record`( 32 ) )")
  end

  def self.down
    drop_table :people
  end
end
