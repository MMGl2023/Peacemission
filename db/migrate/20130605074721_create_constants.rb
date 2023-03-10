class CreateConstants < ActiveRecord::Migration[6.0]
  def self.up
    create_table :constants do |t|
      t.string :name
      t.string :value

      t.timestamps
    end
    add_index :constants, :name
  end

  def self.down
    drop_table :constants
  end
end
