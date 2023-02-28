class CreateRequests < ActiveRecord::Migration[6.0]
  def self.up
    create_table :requests, :force=>true do |t|
      t.integer :request_type
      t.string :full_name
      t.string :relation
      t.string :address, :limit=>1048
      t.string :phone_number
      t.string :email
      t.string :contacts


      t.string  :lost_full_name
      t.date    :lost_birth_date
      t.integer :lost_birth_year
      t.string  :lost_last_location
      t.string  :lost_address, :limit=>1024
      t.date    :lost_on

      t.integer :person_id, :lost_id

      t.text    :details
      t.integer :status

      t.timestamps
    end

    [:request_type, :full_name, :address, :email, :contacts, :status,
      :lost_id, :person_id,
      :lost_full_name, :lost_birth_date, :lost_address, :lost_birth_year, :lost_last_location].each do |f|
      add_index :requests, f
    end

    add_text_index :requests, :details
    # execute " ALTER TABLE `requests` ADD INDEX `index_requests_on_details` ( `details` ( 128 ) )"
  end

  def self.down
    drop_table :requests
  end
end
