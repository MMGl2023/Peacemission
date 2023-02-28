class CreatePermissions <ActiveRecord::Migration
  def self.up


    create_table "permissions", :force => true do |t|
      t.string "permission"
      t.string "description"
    end

    create_table "roles", :force => true do |t|
      t.string "role"
      t.text   "description"
    end

    create_table "roles_permissions", :force => true do |t|
      t.integer "role_id"
      t.integer "permission_id"
    end

    create_table "roles_users", :force => true do |t|
      t.integer "user_id"
      t.integer "role_id"
    end

    add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
    add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"

  end

  def self.down
    drop_table :roles
    drop_table :permissions
    drop_table :roles_permissions
    drop_table :roles_users
  end
end
