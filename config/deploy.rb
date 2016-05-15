require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'
require 'mina/puma'
require 'mina_sidekiq/tasks'

set :user, 'yinsigan'
set :domain, 'rails365.net'
set :deploy_to, '/home/yinsigan/rails365'
set :repository, 'git@github.com:yinsigan/rails365.git'
set :branch, 'master'
set :term_mode, nil
set :puma_config, -> { "#{deploy_to}/#{current_path}/config/puma_app.rb" }

task :environment do
  invoke :'rbenv:load'
end

set :shared_paths, ['config/database.yml', 'config/application.yml', 'log', 'tmp/sockets', 'tmp/pids', 'pids']

task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/log"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/config"]

  queue! %[touch "#{deploy_to}/#{shared_path}/config/database.yml"]
  queue  %[echo "-----> Be sure to edit '#{deploy_to}/#{shared_path}/config/database.yml'."]

  queue! %[touch "#{deploy_to}/#{shared_path}/config/application.yml"]
  queue  %[echo "-----> Be sure to edit '#{deploy_to}/#{shared_path}/config/application.yml'."]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/tmp/sockets"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/tmp/sockets"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/tmp/pids"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/tmp/pids"]

  queue! %[mkdir -p "#{deploy_to}/shared/pids/"]
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  to :before_hook do

  end
  deploy do
    invoke :'sidekiq:quiet'
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    to :launch do
      invoke :'puma:restart'
      invoke :'sidekiq:restart'
    end
  end
end

desc "Shows logs."
task :logs do
  queue %[cd #{deploy_to!}/current && tail -f log/production.log]
end

desc "Display the unicorn logs."
task :unicorn_logs do
  queue 'echo "Contents of the unicorn log file are as follows:"'
  queue "tail -f #{deploy_to}/current/log/unicorn.log"
end
