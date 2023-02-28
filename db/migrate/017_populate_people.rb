MONTHS = %w(январь февраль март апрель май июнь июль август сентябрь октябрь ноябрь декабрь)

def parse_date(str)
  ans = {}

  ans[:year] = $1.to_i if str =~ /(\d\d\d\d)/
  ans[:month] = MONTHS.index($1) if str =~ /#{MONTHS.join('|')}/

  case str
  when /(\d\d)\.?\s*-\s*(\d\d)\.(\d\d)\.(\d\d\d\d)/
    ans = {:day=>$1.to_i, :month=>$3.to_i, :year=>$4.to_i}
  when /(\d\d)\.(\d\d)\.(\d\d\d\d)/
    ans = {:day=>$1.to_i, :month=>$2.to_i, :year=>$3.to_i}
  when /(\d\d\d\d)\.(\d\d)\.(\d\d)/
    ans = {:day=>$3.to_i, :month=>$2.to_i, :year=>$1.to_i}
  when /(\d\d)\.(\d\d\d\d)/
    ans.merge! :month=>$1.to_i, :year=>$2.to_i
  end
  ans
end

def set_date(record, attr, attr_year, h)
  begin
    record.send(attr_year + '=', h[:year]) if h[:year]
    record.send(attr + '=', h.to_date) 
  rescue=>e
  end
end


class PopulatePeople < ActiveRecord::Migration
  def self.up
    
    fields = [:id, :full_name, :birth_date, :last_address, :disappear_on, :disappear_location, :anket_n] 
    
    gz_file_name = File.join( File.dirname(__FILE__), '..', 'bootstrap_data', 'people.csv.gz' )  
    file_name = File.join( File.dirname(__FILE__), '..', 'bootstrap_data', 'people.csv' )  
    
    gz_cmd =  "gzip -d #{gz_file_name} -c > #{file_name}"
    puts "Executing: #{gz_cmd}"
    `#{gz_cmd}`
    
    File.open( file_name ) do |f|
      f.each do |line|
        line.strip! 
        # puts line
        next if line.blank?
        
        values = line.split('|').map(&:strip)
        p = {:orig_record => line}
        fields.zip(values).each do |k, v|
          p[k] = v
        end
        
        person = Person.new(p)
        set_date(person, 'birth_date', 'birth_year', parse_date( p[:birth_date] ))
        set_date(person, 'disappear_on', 'disappear_year', parse_date( p[:disappear_on] ))
        
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
        end
       
        reset_pk.call
      end
    end
    
    `rm #{file_name}`
  end

  def self.down
    # Person.find(:all, :conditions=>'id <= 4616').each(&:delete)
  end
end
