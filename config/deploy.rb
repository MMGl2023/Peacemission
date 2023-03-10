# frozen_string_literal: true
lock "~> 3.17.2"

# Change the YOUR_GITHUB_NAME to your github user name
set :repo_url, "git@github.com:MMGl2023/Peacemission.git"
set :application, "rozysk"
set :user, 'webmaster'
set :puma_threads, [4, 16]
set :puma_workers, 0

# Don't change these unless you know what you're doing
set :pty, true
# set :use_sudo, false
set :stage, :production
set :deploy_via, :remote_cache
set :deploy_to, "/home/#{fetch(:user)}/apps/#{fetch(:application)}"
set :puma_bind, "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log, "#{release_path}/log/puma.access.log"
set :ssh_options, { forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa.pub) }
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true # Change to false when not using ActiveRecord

set :keep_releases, 3

set :branch, 'main'
set :initial, true

append :linked_files, "config/database.yml", 'config/master.key', 'config/puma.rb'
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/webpacker", "public/system", "vendor", "storage", "public/assets", "public/s"

namespace :puma do
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end

  before :start, :make_dirs
end

namespace :deploy do
  desc "Make sure local git is in sync with remote."
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/#{fetch(:branch)}`
        puts "WARNING: HEAD is not the same as origin/#{fetch(:branch)}"
        puts "Run `git push` to sync changes."
        exit
      end
    end
  end

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke 'puma:restart'
    end
  end

  # upload configuration files
  before :starting, 'config_files:upload'

  before :starting, :check_revision
  after :finishing, :compile_assets
  after :finishing, :cleanup
  after :finishing, :restart
end

#
# 23 2 * * * root /home/webmaster/rozysk.org/script/clear_logs
# 30 3 * * * root /home/webmaster/rozysk.org/script/httpd_restart
#
# s.rozysk.org -> /home/webmaster/mmgl/branches/v2.0/public
# static.rozysk.org -> static_rozysk_mongrel_cluster
# rozysk.org -> rozysk_mongrel_cluster
# www.rozysk.org -> www_rozysk_mongrel_cluster
#
