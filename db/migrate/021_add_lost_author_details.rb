class AddLostAuthorDetails < ActiveRecord::Migration
  @@columns = %w(author_full_name author_email author_phone_number author_address author_contacts)
  def self.up
    @@columns.each do |c|
      add_column :losts, c, :string
      add_index :losts, c
    end
    add_column :losts, :lost_on_year, :integer
    add_index :losts, :lost_on_year
    add_column :losts, :found_on_year, :integer
    add_index :losts, :found_on_year
  end

  def self.down
    @@columns.each do |c|
      remove_index :losts, c
      remove_column :losts, c
    end 
    remove_index :losts, :lost_on_year
    remove_column :losts, :lost_on_year
    remove_index :losts, :found_on_year
    remove_column :losts, :found_on_year
  end
end

