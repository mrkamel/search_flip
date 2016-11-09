
require "minitest"
require "minitest/autorun"
require "elastic_search"
require "active_record"
require "factory_girl"
require "yaml"

ActiveRecord::Base.establish_connection YAML.load_file(File.expand_path("../database.yml", __FILE__))

FactoryGirl.define do
  factory :product do
  end
end

ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS products"

ActiveRecord::Base.connection.create_table :products do |t|
end

class ElasticSearch::TestCase < MiniTest::Test
  def teardown
    Product.delete_all
  end
end

