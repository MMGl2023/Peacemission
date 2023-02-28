namespace :fitems do
  desc 'Dump fitems to db/bootstrap_data/[fitems.yml, fitems/*.tgz] files'
  task :dump => :environment  do
    ENV['MODEL'] = "Fitem"
    Rake::Task['db:data:dump'].invoke

    # files = (`find #{Fitem.dir} | grep '/ids/' | egrep -v '\.\w+$'` ||'').split(/\n/)
    
    base_name = File.basename(Fitem.dir)
    src_dir  = File.join(Fitem.dir, 'ids')
    fitems_dir = File.join(RAILS_ROOT, 'db', 'bootstrap_data', 'fitems')
    FileUtils.mkdir_p fitems_dir
    FileUtils.cd fitems_dir
    dest_dir =  base_name

    puts "Copying fitems from '#{src_dir}' to '#{fitems_root}'"
    FileUtils.rm_rf dest_dir if File.exist?(dest_dir)
    FileUtils.cp_r src_dir, dest_dir
    Dir.foreach(dest_dir) do |i|
      FileUtils.rm File.join(dest_dir, i) if i =~ /\.\w+$/
    end
    `tar czf #{dest_dir}.tgz #{dest_dir}`
    # FileUtils.rm_rf dest_dir
    puts "Fitems archive is #{dest_dir}.tgz"
  end

  desc 'Load fitems from db/bootstrap_data/[fitems.yml, fitems/*.tgz] files'
  task :load => :environment do
   
    base_name = File.basename(Fitem.dir)
    fitems_home  = File.join(Fitem.dir)
    FileUtils.mkdir_p fitems_home
    archive = File.join(RAILS_ROOT, 'db', 'bootstrap_data', 'fitems', "#{base_name}.tgz")
    FileUtils.cp archive, fitems_home
    FileUtils.cd fitems_home
    puts `tar xvzf #{base_name}.tgz;`
    `mv ids ids_old` if File.exists?('ids')
    `mv -f #{base_name} ids`
    puts "Please, remove ids_old directory in #{fitems_home}"

    ENV['MODEL'] = "Fitem"
    Rake::Task['db:data:load'].invoke
 
    # Fitem.each do |fitem|
    #  fitem.create_links
    # end
  end
end
