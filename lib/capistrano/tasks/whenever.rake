namespace :whenever do
  desc 'Update cron job'
  task :update_crontab do
    on roles(:app) do
      within current_path do
        execute :bundle, :exec, "whenever --update-crontab #{fetch :whenever_identifier} --set 'environment=#{fetch(:stage)}'"
      end
    end
  end
end
