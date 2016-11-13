
require "minitest"
require "minitest/autorun"
require "mocha/mini_test"
require "elastic_search"
require "active_record"
require "factory_girl"
require "yaml"

ActiveRecord::Base.establish_connection YAML.load_file(File.expand_path("../database.yml", __FILE__))

ElasticSearch::Config[:environment] = "test"

ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS products"

ActiveRecord::Base.connection.create_table :products do |t|
  t.string :title
  t.text :description
  t.float :price
  t.timestamps null: false
end

class Product < ActiveRecord::Base; end

FactoryGirl.define do
  factory :product do
  end
end

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
  include FactoryGirl::Syntax::Methods

  def self.should_delegate_method(method, to:, subject:)
    define_method :"test_delegate_#{method}_to_#{to}" do
      assert subject.respond_to?(method), "subject doesn't respond to #{method}"

      target = subject.send(to)

      assert target.respond_to?(method), "#{to} doesn't respond to #{method}"

      mock_target = mock
      mock_target.expects(method)

      subject.stubs(to).returns(mock_target)

      params = subject.method(method).arity.abs.times.map { |i| "param-#{i}" }

      subject.send(method, *params)
    end
  end

  def self.should_delegate_methods(*methods, to:, subject:)
    methods.each do |method|
      should_delegate_method method, to: to, subject: subject
    end
  end

  def teardown
    mocha_teardown

    ProductIndex.match_all.delete
    Product.delete_all
  end
end

