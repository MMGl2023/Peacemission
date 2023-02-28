class AddFitemFileHash < ActiveRecord::Migration
  def self.up
    add_column :fitems, :file_hash, :string, :limit=>40
    Fitem.each do |f|
      f.ensure_file_hash
    end
  end

  def self.down
    remove_column :fitems, :file_hash
  end
end
