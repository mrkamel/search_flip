
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
  t.string :title
  t.text :description
  t.float :price
  t.timestamps null: false
end

class Product < ActiveRecord::Base; end

class ProductIndex
  include ElasticSearch::Index

  def self.mapping
    { :products => {} }
  end

  def self.type_name
    "products"
  end

  def self.model
    Product
  end
end

class TestIndex
  include ElasticSearch::Index

  def self.mapping
    {
      :test => {
        :properties => {
          :test_field => { :type => "string" }
        }
      }
    }
  end

  def self.type_name
    "test"
  end
end

ProductIndex.delete_index if ProductIndex.index_exists?
ProductIndex.create_index
ProductIndex.update_mapping

class ElasticSearch::TestCase < MiniTest::Test
  def teardown
    ProductIndex.match_all.delete
    Product.delete_all
  end
end

