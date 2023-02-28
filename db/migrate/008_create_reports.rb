class CreateReports <ActiveRecord::Migration[6.0]
  def self.up

    create_table "reports", :force => true do |t|
      t.string   "report_type", :limit => 32
      t.string   "subject",     :limit => 1024
      t.text     "details"
      t.integer  "user_id"
      t.string   "name",        :limit => 256
      t.string   "email",       :limit => 128
      t.string   "os",          :limit => 128
      t.string   "browser",     :limit => 128
      t.datetime "created_at"
      t.boolean  "replied"
    end

    add_index "reports", ["report_type"], :name => "index_reports_on_report_type"
    add_index "reports", ["subject"], :name => "index_reports_on_subject"
    add_index "reports", ["user_id"], :name => "index_reports_on_user_id"
    add_index "reports", ["name"], :name => "index_reports_on_name"
    add_index "reports", ["email"], :name => "index_reports_on_email"
    add_index "reports", ["os"], :name => "index_reports_on_os"
    add_index "reports", ["browser"], :name => "index_reports_on_browser"
    add_index "reports", ["created_at"], :name => "index_reports_on_created_at"
    add_index "reports", ["replied"], :name => "index_reports_on_replied"

  end

  def self.down
  end
end
