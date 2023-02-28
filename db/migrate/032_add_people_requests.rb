class AddPeopleRequests < ActiveRecord::Migration
  def self.up
    create_table :people_requests, :force=>true do |t|
      t.column :person_id, :integer
      t.column :request_id, :integer
    end
    [:request_id, :person_id].each do |f|
      add_index :people_requests, f
    end
  end

  def self.down
    drop_table :people_requests
  end
end
