namespace :db do
  namespace :backup do

    def interesting_tables
      ActiveRecord::Base.connection.tables.sort.reject! do |tbl|
        ['schema_info', 'sessions', 'public_exceptions'].include?(tbl)
      end
    end

    desc "Reload the database and rerun migrations" 
    task :redo do 
      Rake::Task['db:backup:write'].invoke
      Rake::Task['db:drop'].invoke
      Rake::Task['db:create'].invoke
      Rake::Task['db:migrate'].invoke
      Rake::Task['db:backup:read'].invoke 
    end 

    desc "Dump entire db." 
    task :write => :environment do 

      dir = RAILS_ROOT + '/db/backup'
      FileUtils.mkdir_p(dir)
      FileUtils.chdir(dir)
      interesting_tables.each do |tbl|
        klass = tbl.classify.constantize
        puts "Writing #{tbl}..." 
        File.open("#{tbl}.yml", 'w+') { |f| YAML.dump(klass.find(:all).collect(&:attributes), f) }      
      end
      FileUtils.chdir(RAILS_ROOT)
    end

    desc "Loads the entire db." 
    task :read => [:environment, 'db:schema:load'] do 

      dir = RAILS_ROOT + '/db/backup'
      FileUtils.mkdir_p(dir)
      FileUtils.chdir(dir)

      interesting_tables.each do |tbl|

        klass = tbl.classify.constantize
        ActiveRecord::Base.transaction do 

          puts "Loading #{tbl}..." 
          YAML.load_file("#{tbl}.yml").each do |fixture|
            data = {}
            klass.columns.each do |c|
              # filter out missing columns 
              data[c.name] = fixture[c.name] if fixture[c.name]
            end         
            ActiveRecord::Base.connection.execute "INSERT INTO #{tbl} (#{data.keys.join(",")}) VALUES (#{data.values.collect { |value| ActiveRecord::Base.connection.quote(value) }.join(",")})", 'Fixture Insert'

        end        
        end
      end

    end

  end
end
