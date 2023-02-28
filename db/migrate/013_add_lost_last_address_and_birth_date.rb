class AddLostLastAddressAndBirthDate < ActiveRecord::Migration[6.0]
  def self.up
    add_column :losts, :last_address, :string
    add_column :losts, :birth_date, :date
  end

  def self.down
    remove_column :losts, :last_address
    remove_column :losts, :birth_date
  end
end
