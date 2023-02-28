class CreateInvitations <ActiveRecord::Migration
  def self.up
    create_table "invitations", :force => true do |t|
      t.string   "name"
      t.text     "text"
      t.string   "email"
      t.integer  "used_by_id"
      t.integer  "created_by_id"
      t.datetime "created_at"
      t.datetime "used_at"
      t.string   "code"
      t.datetime "expired_at"
      t.string   "subject"
    end

    add_index "invitations", ["used_by_id"]
    add_index "invitations", ["created_by_id"]
    add_index "invitations", ["code"]
    add_index "invitations", ["expired_at"]
  end

  def self.down
    drop_table :invitations
  end
end
