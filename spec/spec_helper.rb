
require "search_flip"
require "webmock/rspec"
require "active_record"
require "factory_bot"
require "timecop"
require "yaml"

require File.expand_path("delegate_matcher", __dir__)

WebMock.allow_net_connect!

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before do
    TestIndex.delete_index if TestIndex.index_exists?
    ProductIndex.match_all.delete
    Product.delete_all
  end
end

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

SearchFlip::Config[:auto_refresh] = true

ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS products"

ActiveRecord::Base.connection.create_table :products do |t|
  t.string :title
  t.text :description
  t.float :price
  t.string :category
  t.integer :version, default: 1
  t.integer :rank, default: 0
  t.integer :user_id
  t.timestamps null: false
end

ActiveRecord::Base.connection.add_index :products, :user_id

class Product < ActiveRecord::Base
  belongs_to :user
  has_many :comments
end

FactoryBot.define do
  factory :product
end

ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS users"

ActiveRecord::Base.connection.create_table :users do |t|
  t.string :name
  t.timestamps null: false
end

class User < ActiveRecord::Base
  has_many :products
end

FactoryBot.define do
  factory :user
end

ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS comments"

ActiveRecord::Base.connection.create_table :comments do |t|
  t.text :message
  t.integer :product_id
  t.timestamps null: false
end

ActiveRecord::Base.connection.add_index :comments, :product_id

class Comment < ActiveRecord::Base
  belongs_to :product
end

FactoryBot.define do
  factory :comment
end

class CommentIndex
  include SearchFlip::Index

  def self.type_name
    "comments"
  end

  def self.index_name
    "comments"
  end

  def self.model
    Comment
  end

  def self.serialize(comment)
    {
      id: comment.id,
      message: comment.message
    }
  end
end

CommentIndex.delete_index if CommentIndex.index_exists?
CommentIndex.create_index
CommentIndex.update_mapping

class ProductIndex
  include SearchFlip::Index

  def self.mapping
    if ProductIndex.connection.version.to_i >= 5
      {
        products: {
          properties: {
            category: {
              type: "text",
              fielddata: true
            },
            title: {
              type: "text",
              fielddata: true
            },
            description: {
              type: "text",
              fielddata: true
            }
          }
        }
      }
    else
      { products: {} }
    end
  end

  def self.type_name
    "products"
  end

  def self.index_name
    "products"
  end

  def self.model
    Product
  end

  def self.serialize(product)
    {
      id: product.id,
      title: product.title,
      description: product.description,
      category: product.category,
      price: product.price,
      rank: product.rank,
      created_at: product.created_at,
      updated_at: product.updated_at
    }
  end
end

ProductIndex.delete_index if ProductIndex.index_exists?
ProductIndex.create_index
ProductIndex.update_mapping

class TestIndex
  include SearchFlip::Index

  def self.mapping
    {
      test: {
        properties: {
          test_field: { type: "date" }
        }
      }
    }
  end

  def self.type_name
    "test"
  end

  def self.index_name
    "test"
  end

  def self.serialize(object)
    { id: object.id }
  end
end

TestIndex.delete_index if TestIndex.index_exists?

