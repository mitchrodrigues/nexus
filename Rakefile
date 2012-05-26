require 'active_record'
require 'yaml'
require 'logger'

PATH = Dir.pwd

require "#{PATH}/include/constants"



task :default => :migrate

desc "Migrate the database through scripts in db/migrate. Target specific version with VERSION=x"
task :migrate => :environment do
  ActiveRecord::Migrator.migrate("#{PATH}/db/migrate", ENV["VERSION"] ? ENV["VERSION"].to_i : nil )
end

task :environment do
  db_config = YAML::load(File.open("#{CONFIG_PATH}/database.yml"))
  ActiveRecord::Base.establish_connection(db_config)
  ActiveRecord::Base.logger = Logger.new(STDOUT)
end