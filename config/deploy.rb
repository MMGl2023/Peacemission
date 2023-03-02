# frozen_string_literal: true
#
# config valid for current version and patch releases of Capistrano
lock "~> 3.17.2"

set :application, "rozysk"
set :repo_url, "git@github.com:MMGl2023/Peacemission.git"
set :user, 'webmaster'
set :puma_threads, [4, 16]
set :puma_workers, 0

set :puma_bind, "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log, "#{release_path}/log/puma.access.log"

set :ssh_options, { forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa.pub) }

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :branch, 'main'

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/home/#{fetch(:user)}/apps/#{fetch(:application)}"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, "config/database.yml", 'config/master.key', 'config/puma.rb'

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/webpacker", "public/system", "vendor", "storage"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/webpacker", "public/system", "vendor", "storage", "public/assets", "public/s"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
set :keep_releases, 3

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

# Skip migration if files in db/migrate were not modified
# Defaults to false
set :conditionally_migrate, true

# Set unique identifier for background jobs
set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }

# ================================================
# ============ From Custom Rake Tasks ============
# ================================================
# ===== See Inside: lib/capistrano/tasks =========
# ================================================

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
  # upload configuration files
  before :starting, 'config_files:upload'

  # set this to false after deploying for the first time
  set :initial, true

  # run only if app is being deployed for the very first time, should update "set :initial, true" above to run this
  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      before 'deploy:migrate', 'database:create'
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  # update cron job from whenever schedule file at "config/schedule.rb"
  after 'deploy:finishing', 'whenever:update_crontab'

  # reload application after successful deploy
  after 'deploy:publishing', 'application:reload'
end
