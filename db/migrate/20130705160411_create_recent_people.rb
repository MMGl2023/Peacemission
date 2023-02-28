$:.unshift File.dirname(__FILE__)
require 'migration_ext'

class CreateRecentPeople < ActiveRecord::Migration[6.0]
  def self.up
    create_table "recent_people", :force => true do |t|
      t.string "full_name"
      t.date "birth_date"
      t.integer "birth_year"
      t.integer "birth_month", :limit => 8
      t.string "last_address"
      t.date "lost_on"
      t.integer "lost_on_year"
      t.integer "lost_on_month", :limit => 8
      t.string "disappear_region"
      t.string "disappear_location"
      t.text "relatives_contacts"
      t.text "info_source"
      t.text "remark"
      t.integer "status", :default => 0

      t.timestamps
    end

    add_index "recent_people", ["full_name", "birth_year"], :name => "index_recent_people_on_full_name_and_birth_year"
    add_index "recent_people", ["birth_date"], :name => "index_recent_people_on_birth_date"
    add_index "recent_people", ["birth_year"], :name => "index_recent_people_on_birth_year"
    add_index "recent_people", ["last_address"], :name => "index_recent_people_on_last_address"
    add_index "recent_people", ["lost_on"], :name => "index_recent_people_on_lost_on"
    add_index "recent_people", ["lost_on_year"], :name => "index_recent_people_on_lost_on_year"
    add_index "recent_people", ["disappear_region"], :name => "index_recent_people_on_disappear_region"
    add_index "recent_people", ["disappear_location"], :name => "index_recent_people_on_disappear_location"
    add_text_index "recent_people", ["relatives_contacts"], :name => "index_recent_people_on_relatives_contacts"
    add_text_index "recent_people", ["info_source"], :name => "index_recent_people_on_info_source"
    add_text_index "recent_people", ["remark"], :name => "index_recent_people_on_remark"
    add_index "recent_people", ["status"], :name => "index_recent_people_on_status"

  end

  def self.down
    drop_table :recent_people
  end
end
