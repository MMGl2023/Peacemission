class AddFitemSizeAndWidthAndHeight < ActiveRecord::Migration[6.0]
  def self.up
    add_column :fitems, :size, :integer
    add_column :fitems, :width, :integer
    add_column :fitems, :height, :integer
    add_index :fitems, :size
  end

  def self.down
    remove_column :fitems, :size
    remove_column :fitems, :width
    remove_column :fitems, :height
  end
end
