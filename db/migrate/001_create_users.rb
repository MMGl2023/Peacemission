class CreateUsers < ActiveRecord::Migration[6.0]
  def self.up

    create_table :users, :force => true do |t|
      t.string :login, :limit => 64
      t.string  :email
      t.boolean :gender

      t.column :crypted_password,          :string, :limit => 40
      t.column :salt,                      :string, :limit => 40
      t.column :activation_code,           :string, :limit => 40
      t.column :password_reset_code,       :string, :limit => 40
      t.column :remember_token,            :string, :limit => 40

      t.column :state, :string, :null => :no, :default => 'passive'

      t.datetime :visited_at, :activated_at, :deleted_at, :remember_token_expires_at
      t.string   :last_ip, :limit => 16

      t.boolean :enabled, :default => true
      t.boolean :hidden, :default => false

      t.string  :full_name

      t.string  :country, :limit => 8
      t.string  :time_zone, :limit => 128
      t.text    :info

      t.integer :image_id

      # t.string :ui_lc, :limit=>64 # localization

      t.timestamps
    end

    [:login, :visited_at, :country, :full_name, :state, :enabled, :hidden].each do |f|
      add_index :users, f
    end

    User.load_from_file('db/bootstrap_data/users.yml')
    User.all.each(&:activate!)
  end

  def self.down
    drop_table :users
  end
end
