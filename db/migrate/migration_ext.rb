require 'method_modifiers'

module MigrationExt
  exception_filter :ensure_add_index, 
      :method => :add_index, 
      :msg_filter => /Duplicate key name/,
      :block => lambda {|type, table, column|  puts "INDEX EXISTS:  #{table}.#{column}" }

  exception_filter :ensure_remove_index, 
      :method => :remove_index, 
      :msg_filter =>  /check that column\/key exists/,
      :block => lambda {|type, table, column|  puts "INDEX DOES NOT EXISTS:  #{table}.#{column}" }
   
  def connection
    ActiveRecord::Base.connection
  end

  def add_text_index(table, column, options={})
    case (connection.adapter_name rescue 'default')
    when 'PostgreSQL', 'default'
      # add_index table, column
    when 'MySQL'
      options[:length] ||= 32
      execute "ALTER TABLE #{table} ADD INDEX `index_#{table}_on_#{column}` ( `#{column}` (#{options[:length]}) )"
    end
  end
end

class ActiveRecord::Migration
  class <<self
    include MigrationExt
  end
end
