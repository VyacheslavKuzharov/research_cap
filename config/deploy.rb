set :repo_url,        'git@github.com:VyacheslavKuzharov/research_cap.git'
set :application,     'research_cap'
set :user,            'deploy'

# Don't change these unless you know what you're doing
set :pty,             true
set :use_sudo,        false
set :deploy_via,      :remote_cache
set :deploy_to,       "/home/#{fetch(:user)}/apps/#{fetch(:application)}"
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log,  "#{release_path}/log/puma.access.log"
set :ssh_options,     { forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa.pub) }
set :bundle_binstubs, nil # to run rails console on server: https://github.com/capistrano/bundler/issues/45
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true  # Change to false when not using ActiveRecord

set :precompile_env,  fetch(:rails_env) || :production
set :assets_dir,      'public/assets'
set :rsync_cmd,       'rsync -av --delete'

## Defaults:
set :keep_releases, 2

## Linked Files & Directories (Default None):
set :linked_files, %w{ config/database.yml config/secrets.yml config/cloudinary.yml }
set :linked_dirs,  %w{ log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system }

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

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  task :copy_config do
    on release_roles :app do |role|
      fetch(:linked_files).each do |linked_file|
        user = "#{fetch(:user)}@"
        hostname = role.hostname
        linked_files(shared_path).each do |file|
          run_locally do
            execute "rsync -avz -e 'ssh -p 2222' config/#{file.to_s.gsub(/.*\/(.*)$/,"\\1")} #{user}#{hostname}:#{file.to_s.gsub(/(.*)\/[^\/]*$/, "\\1")}/"
          end
        end
      end
    end
  end

  before 'deploy:check:linked_files', 'deploy:copy_config'
  after  :finishing,    :compile_assets
  after  :finishing,    :cleanup
  after  :finishing,    :restart
end

# ps aux | grep puma    # Get puma pid
# kill -s SIGUSR2 pid   # Restart puma
# kill -s SIGTERM pid   # Stop puma
