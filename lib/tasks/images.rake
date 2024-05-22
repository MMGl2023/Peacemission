require 'erb'
require 'yaml'

namespace :images do
  # command line usage: rake db:version
  desc "Returns the current schema version"
  task version: :environment do
    puts "Current version: " + ActiveRecord::Migrator.current_version.to_s
    puts ActiveRecord::Base.connection.to_yaml
    puts ARGV.inspect
  end

  desc "create static images archive s_<time_stamp>.tgz"
  task :dump, [:dir] => :environment do |t, args|
    read_db_config
    file = "s_#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}.tgz"
    dir = args['dir'] || ENV['MYSQL_DUMP_DIR'] || 'db_backups'
    FileUtils.mkdir_p(dir)

    puts "Remove older than 2-days"
    cmd = "find #{dir} -mindepth 1 -mtime +2 -delete"
    puts cmd
    system(cmd)

    file = File.join(dir, file)
    puts "Creating tgz file '#{file}'."
    cmd = "tar -czf #{file} /home/webmaster/apps/rozysk/shared/public/s"
    puts cmd
    system(cmd)
  end
end

