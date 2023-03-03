require 'erb'
require 'yaml'

namespace :db do

  def read_db_config
    unless @db_config = YAML::load(ERB.new(IO.read(Rails.root.join("config/database.yml"))).result)[Rails.env]
      abort "No database is configured for the environment '#{env}'"
    end

    args = {
      'host'      => '--host',
      'port'      => '--port',
      'socket'    => '--socket',
      'username'  => '--user',
      'encoding'  => '--default-character-set'
    }.map { |opt, arg| "#{arg}=#{@db_config[opt]}" if @db_config[opt] }.compact

    if @db_config['password']
      args << "--password=#{@db_config['password']}"
    elsif @db_config['password'] && !@db_config['password'].to_s.empty?
      args << "-p"
    end

    args << @db_config['database']

    @mysql_options = args.join(" ")
  end

  # command line usage: rake db:version
  desc "Returns the current schema version"
  task :version => :environment do
    puts "Current version: " + ActiveRecord::Migrator.current_version.to_s
    puts ActiveRecord::Base.connection.to_yaml
    puts ARGV.inspect
  end

  desc "dumps database to a sql file <database>_<time_stamp>.sql.gz"
  task :sqldump, [:dir] => :environment do |t,args|
    read_db_config
    file = ENV['DUMP'] || "#{@db_config['database']}_#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}.sql.gz"
    dir = args['dir'] || ENV['MYSQL_DUMP_DIR'] || 'db_backups'
    FileUtils.mkdir_p(dir)
    file = File.join(dir, file)
    puts "Creating dump file '#{file}'."
    cmd = "mysqldump #{@mysql_options} --ignore-table=#{@db_config['database']}.sessions | gzip > #{file}"
    puts cmd
    # system(cmd)
  end

  #command line usage: rake db:dumpimport
  desc "loads sql.gz dump file to database (use DUMP=<dump_name>) in command line"
  task :sqlload => :environment do
    file = ENV['DUMP'] || "#{@db_config['database']}_#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}.sql.gz"
    dir = args['dir'] || ENV['MYSQL_DUMP_DIR'] || 'db_backups'
    file = File.join(dir, file)
    cmd = (file ?
      (file =~ /\.gz$/ ? "zcat #{file} |" : "cat #{file}") :
      ""
    )
    puts "Loading dump from #{file || 'STDIN'}."
    `#{cmd} | mysql #{@mysql_options}`
  end
end

