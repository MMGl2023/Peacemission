$:.unshift File.dirname(__FILE__)
require 'migration_ext'

MONTHS = %w(январь февраль март апрель май июнь июль август сентябрь октябрь ноябрь декабрь)

def parse_date(str)
  ans = {}

  ans[:year] = $1.to_i if str =~ /(\d\d\d\d)/
  ans[:month] = MONTHS.index($1) if str =~ /#{MONTHS.join('|')}/

  case str
  when /(\d\d)\.?\s*-\s*(\d\d)\.(\d\d)\.(\d\d\d\d)/
    ans = {:day => $1.to_i, :month => $3.to_i, :year => $4.to_i}
  when /(\d\d)\.(\d\d)\.(\d\d\d\d)/
    ans = {:day => $1.to_i, :month => $2.to_i, :year => $3.to_i}
  when /(\d\d\d\d)\.(\d\d)\.(\d\d)/
    ans = {:day => $3.to_i, :month => $2.to_i, :year => $1.to_i}
  when /(\d\d)\.(\d\d\d\d)/
    ans.merge! :month => $1.to_i, :year => $2.to_i
  end
  ans
end

def new_set_date(record, attr, attr_year, attr_month, h)
  begin
    record.send(attr_year + '=', h[:year]) if h[:year]
    record.send(attr_month + '=', h[:month]) if h[:month]
    record.send(attr + '=', h.to_date)
  rescue=>e
  end
end

class RepopulatePeople < ActiveRecord::Migration
  def self.up
    drop_table :people

    create_table :people, :force => true do |t|
      t.string   :full_name
      t.date     :birth_date
      t.integer  :birth_year,         :limit => 11
      t.integer  :birth_month,        :limit => 8
      t.string   :last_address
      t.date     :lost_on
      t.integer  :lost_on_year,       :limit => 11
      t.integer  :lost_on_month,      :limit => 8
      t.string   :disappear_region
      t.string   :disappear_location
      t.integer  :anket_n,            :limit => 11
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :lost_id,            :limit => 11

      t.text    :orig_record
      t.text    :relatives_contacts
      t.text    :info_source
      t.text    :remark

      t.timestamps
    end
    
    [
      [:full_name, :birth_year], 
      :birth_date, :birth_year,
      :last_address, 
      :anket_n,
      :lost_on, :lost_on_year,
      :disappear_region,
      :disappear_location,
      :lost_id
    ].each do |f| 
      ensure_add_index :people, f
    end

    [:orig_record, :relatives_contacts, :info_source, :remark].each do |f|
      add_text_index :people, f
    end
   
    fields = [:id, :full_name, :birth_date, :last_address, :lost_on, :disappear_location, :relatives_contacts, :anket_n, :info_source, :remark] 
    
    file_name = File.join( File.dirname(__FILE__), '..', 'bootstrap_data', 'people.csv' )
    gz_file_name = file_name + '.gz'
    
    gz_cmd =  "gzip -d #{gz_file_name} -c > #{file_name}"
    puts "Executing: #{gz_cmd}"
    puts `#{gz_cmd}`

    raise RuntimeError, "No file #{file_name}" unless File.exist?(file_name)
    
    File.open( file_name ) do |f|
      f.each do |line|
        line.strip!
        line << ' '
        # puts line
        next if line.blank?
        
        values = line.split('|').map(&:strip)

        if values.size != fields.size
          puts fields.inspect, fields.size
          puts values.inspect, values.size
          raise ArgumentError, "Bad people list format: #{line}"
        end

        p = {:orig_record => line}
        fields.zip(values).each do |k, v|
          p[k] = v
        end
        
        person = Person.new(p)
        new_set_date(person, 'birth_date', 'birth_year', 'birth_month', parse_date( p[:birth_date] ))
        new_set_date(person, 'lost_on', 'lost_on_year', 'lost_on_month', parse_date( p[:lost_on] ))
        
        conn = Person.connection
        reset_pk = lambda do 
          if conn.respond_to?(:reset_pk_sequence!)
            conn.reset_pk_sequence!( Person.table_name )
          end
        end
        
        reset_pk.call
        
        person.id = p[:id]
        if person.save
          puts "#{p[:id]}: OK!"
        else
          puts "#{p[:id]}: BAD! : #{person.errors.full_messages.join("; ")}"
          break
        end
       
        reset_pk.call
      end
    end
    
    `rm #{file_name}`
  end

  def self.down
    
  end
end
