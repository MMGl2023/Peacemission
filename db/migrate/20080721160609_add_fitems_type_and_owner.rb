class AddFitemsTypeAndOwner < ActiveRecord::Migration
  def self.up
    add_column :fitems, :type, :string, :limit => 40
    add_column :fitems, :owner_id, :integer
    add_column :fitems, :owner_type, :string, :limit => 40, :default => "Fitem"

    add_index :fitems, [:type]
    add_index :fitems, [:owner_type, :owner_id]

    Fitem.each do |f|
      f.type = "Fitem"
    end
  end

  def self.down
    remove_column :fitems, :type
    remove_column :fitems, :owner_id
    remove_column :fitems, :owner_type
  end
end
