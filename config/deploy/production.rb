set :stage, :production
set :branch, 'master'
set :rails_env, 'production'
set :console_env, :production

server 'deploy@52.42.205.41', port: 2222, roles: [:web, :app, :db], primary: true
