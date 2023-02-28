class CorrectPeopleOrigRecord < ActiveRecord::Migration
  def self.up
    file_name = File.join( File.dirname(__FILE__), '..', 'bootstrap_data', 'people_with_old_dates.csv')
    gz_file_name = file_name + '.gz'
    
    gz_cmd = "gzip -d #{gz_file_name} -c > #{file_name}"
    puts "Executing: #{gz_cmd}"
    puts `#{gz_cmd}`

    File.open(file_name) do |f|
      f.each do |line|
        next if line.blank? || line =~ /^\s*#/
        line.gsub!('|', ' | ')
        line.strip!
        values = line.split('|')
        id = values.first.to_i

        next if id <= 0 || id >= 5000
        p = Person.find_by_id(id)
        if p
          p.orig_record = line
          p.relatives_contacts = values[6].strip
          p.save!
        else
          raise RuntimeError, "can't find person with id #{id}"
        end
      end
    end
    `rm #{file_name}`
  end

  def self.down
  end
end
 
