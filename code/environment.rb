require 'rest_client'
require 'csv'
require 'sidekiq'
require 'sidekiq/api'
require 'time'
require 'mongo_mapper'
require 'json'
require 'pry'
Dir[File.dirname(__FILE__) + '/extensions/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/lib/baumgartner_dataset/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/tasks/*.rb'].each {|file| require file }
CONFIG = JSON.parse(File.read("settings.json"))
$redis = Redis.new
MongoMapper.connection = Mongo::MongoClient.new(CONFIG["db_host"], 27017, :pool_size => 25, :op_timeout => 600000, :timeout => 600000, :pool_timeout => 600000)
MongoMapper.connection["admin"].authenticate(CONFIG["db_user"], CONFIG["db_password"])
MongoMapper.database = CONFIG["database"]
NodeWalkerDiffs.ensure_index([[:dataset_tag, 1], [:strftime_str, 1], [:percentile, 1], [:cumulative_post_cutoff, 1], [:time, 1]])