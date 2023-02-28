class CreateComments < ActiveRecord::Migration[6.0]
  def self.up
    create_table :comments, :force=>true do |t|
      t.string :subject, :limit=>1024
      t.text :body
      t.integer :obj_id
      t.string :obj_type, :limit=>64
      t.integer :root_id
      t.integer :author_id
      t.string :author_name, :limit=>128
      t.string :engine, :limit=>32
      t.string :session_id
      t.string :state, :limit=>32, :default=>'active'
      t.datetime :thread_updated_at

      t.timestamps
    end

    [ [:obj_type, :obj_id],
      :author_id, :author_name, :state,
      [:root_id, :thread_updated_at],
      [:created_at, :root_id]
    ].each do |f|
      add_index :comments, f
    end

  end

  def self.down
    #drop_table :comments
  end
end
