
require File.expand_path("../../test_helper", __FILE__)

class ElasticSearch::RelationTest < ElasticSearch::TestCase
  should_delegate_methods :total_entries, :current_page, :previous_page, :prev_page, :next_page, :first_page?, :last_page?, :out_of_range?,
    :total_pages, :hits, :ids, :count, :size, :length, :took, :aggregations, :suggestions, :scope, :results, :records, :scroll_id, :raw_response,
    to: :response, subject: ElasticSearch::Relation.new(target: ProductIndex)

  def test_merge
    product1 = create(:product, price: 100, category: "category1")
    product2 = create(:product, price: 200, category: "category2")
    product3 = create(:product, price: 300, category: "category1")

    ProductIndex.import [product1, product2, product3]

    query = ProductIndex.where(price: 50 .. 250).aggregate(:category).merge(ProductIndex.where(category: "category1"))

    assert_includes query.records, product1
    refute_includes query.records, product2
    refute_includes query.records, product3
  end

  def test_relation
    relation = ProductIndex.relation

    assert relation.relation === relation
  end

  def test_timeout
    query = ProductIndex.timeout("1s")

    assert_equal "1s", query.request[:timeout]

    query.execute
  end

  def test_terminate_after
    query = ProductIndex.terminate_after(1)

    assert_equal 1, query.request[:terminate_after]

    query.execute
  end

  def test_where
    product1 = create(:product, price: 100, category: "category1")
    product2 = create(:product, price: 200, category: "category2")
    product3 = create(:product, price: 300, category: "category1")

    ProductIndex.import [product1, product2, product3]

    query1 = ProductIndex.where(price: 100 .. 200)
    query2 = query1.where(category: "category1")

    assert_includes query1.records, product1
    assert_includes query1.records, product2
    refute_includes query1.records, product3

    assert_includes query2.records, product1
    refute_includes query2.records, product2
    refute_includes query2.records, product3
  end

  def test_where_with_array
    expected1 = create(:product, title: "expected1")
    expected2 = create(:product, title: "expected2")
    rejected = create(:product, title: "rejected")

    ProductIndex.import [expected1, expected2, rejected]

    records = ProductIndex.where(title: ["expected1", "expected2"]).records

    assert_includes records, expected1
    assert_includes records, expected2
    refute_includes records, rejected
  end

  def test_where_with_range
    expected1 = create(:product, price: 100)
    expected2 = create(:product, price: 200)
    rejected = create(:product, price: 300)

    ProductIndex.import [expected1, expected2, rejected]

    records = ProductIndex.where(price: 100 .. 200).records

    assert_includes records, expected1
    assert_includes records, expected2
    refute_includes records, rejected
  end

  def test_where_not
    product1 = create(:product, price: 100, category: "category1")
    product2 = create(:product, price: 200, category: "category2")
    product3 = create(:product, price: 300, category: "category1")

    ProductIndex.import [product1, product2, product3]

    query1 = ProductIndex.where_not(price: 250 .. 350)
    query2 = query1.where_not(category: "category2")

    assert_includes query1.records, product1
    assert_includes query1.records, product2
    refute_includes query1.records, product3

    assert_includes query2.records, product1
    refute_includes query2.records, product2
    refute_includes query2.records, product3
  end

  def test_where_not_with_array
    expected = create(:product, title: "expected")
    rejected1 = create(:product, title: "rejected1")
    rejected2 = create(:product, title: "rejected2")

    ProductIndex.import [expected, rejected1, rejected2]

    records = ProductIndex.where_not(title: ["rejected1", "rejected2"]).records

    assert_includes records, expected
    refute_includes records, rejected1
    refute_includes records, rejected2
  end

  def test_where_not_with_range
    expected = create(:product, price: 100)
    rejected1 = create(:product, price: 200)
    rejected2 = create(:product, price: 300)

    ProductIndex.import [expected, rejected1, rejected2]

    records = ProductIndex.where_not(price: 200 .. 300).records

    assert_includes records, expected
    refute_includes records, rejected1
    refute_includes records, rejected2
  end

  def test_filter
    product1 = create(:product, price: 100, category: "category1")
    product2 = create(:product, price: 200, category: "category2")
    product3 = create(:product, price: 300, category: "category1")

    ProductIndex.import [product1, product2, product3]

    query1 = ProductIndex.filter(range: { price: { gte: 100, lte: 200 }})
    query2 = query1.filter(term: { category: "category1" })

    assert_includes query1.records, product1
    assert_includes query1.records, product2
    refute_includes query1.records, product3

    assert_includes query2.records, product1
    refute_includes query2.records, product2
    refute_includes query2.records, product3
  end

  def test_range
    product1 = create(:product, price: 100)
    product2 = create(:product, price: 200)
    product3 = create(:product, price: 300)

    ProductIndex.import [product1, product2, product3]

    query1 = ProductIndex.range(:price, gte: 100, lte: 200)
    query2 = query1.range(:price, gte: 200, lte: 300)

    assert_includes query1.records, product1
    assert_includes query1.records, product2
    refute_includes query1.records, product3

    refute_includes query2.records, product1
    assert_includes query2.records, product2
    refute_includes query2.records, product3
  end

  def test_match_all
    expected1 = create(:product)
    expected2 = create(:product)

    ProductIndex.import [expected1, expected2]

    records = ProductIndex.match_all.records

    assert_includes records, expected1
    assert_includes records, expected2
  end

  def test_exists
    product1 = create(:product, title: "title1", description: "description1")
    product2 = create(:product, title: "title2", description: nil)
    product3 = create(:product, title: nil, description: "description2")

    ProductIndex.import [product1, product2, product3]

    query1 = ProductIndex.exists(:title)
    query2 = query1.exists(:description)

    assert_includes query1.records, product1
    assert_includes query1.records, product2
    refute_includes query1.records, product3

    assert_includes query2.records, product1
    refute_includes query2.records, product2
    refute_includes query2.records, product3
  end

  def test_exists_not
    product1 = create(:product, title: nil, description: nil)
    product2 = create(:product, title: nil, description: "description2")
    product3 = create(:product, title: "title3", description: "description3")

    ProductIndex.import [product1, product2, product3]

    query1 = ProductIndex.exists_not(:title)
    query2 = query1.exists_not(:description)

    assert_includes query1.records, product1
    assert_includes query1.records, product2
    refute_includes query1.records, product3

    assert_includes query2.records, product1
    refute_includes query2.records, product2
    refute_includes query2.records, product3
  end

  def test_post_search
    return if ElasticSearch.version.to_i < 2

    product1 = create(:product, title: "title1", category: "category1")
    product2 = create(:product, title: "title2", category: "category2")
    product3 = create(:product, title: "title3", category: "category1")

    ProductIndex.import [product1, product2, product3]

    query1 = ProductIndex.aggregate(:category).post_search("title1 OR title2")
    query2 = query1.post_search("category1")

    assert_includes query1.records, product1
    assert_includes query1.records, product2
    refute_includes query1.records, product3

    assert_includes query2.records, product1
    refute_includes query2.records, product2
    refute_includes query2.records, product3

    assert_equal Hash["category1" => 2, "category2" => 1], query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
    assert_equal Hash["category1" => 2, "category2" => 1], query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
  end

  def test_post_where
    product1 = create(:product, price: 100, category: "category1")
    product2 = create(:product, price: 200, category: "category2")
    product3 = create(:product, price: 300, category: "category1")

    ProductIndex.import [product1, product2, product3]

    query1 = ProductIndex.aggregate(:category).post_where(price: 100 .. 200)
    query2 = query1.post_where(category: "category1")

    assert_includes query1.records, product1
    assert_includes query1.records, product2
    refute_includes query1.records, product3

    assert_includes query2.records, product1
    refute_includes query2.records, product2
    refute_includes query2.records, product3

    assert_equal Hash["category1" => 2, "category2" => 1], query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
    assert_equal Hash["category1" => 2, "category2" => 1], query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
  end

  def test_post_where_with_array
    expected1 = create(:product, title: "expected1", category: "category1")
    expected2 = create(:product, title: "expected2", category: "category2")
    rejected = create(:product, title: "rejected", category: "category1")

    ProductIndex.import [expected1, expected2, rejected]

    query = ProductIndex.aggregate(:category).post_where(title: ["expected1", "expected2"])

    assert_includes query.records, expected1
    assert_includes query.records, expected2
    refute_includes query.records, rejected

    assert_equal Hash["category1" => 2, "category2" => 1], query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
  end

  def test_post_where_with_range
    expected1 = create(:product, price: 100, category: "category1")
    expected2 = create(:product, price: 200, category: "category2")
    rejected = create(:product, price: 300, category: "category1")

    ProductIndex.import [expected1, expected2, rejected]

    query = ProductIndex.aggregate(:category).post_where(price: 100 .. 200)

    assert_includes query.records, expected1
    assert_includes query.records, expected2
    refute_includes query.records, rejected

    assert_equal Hash["category1" => 2, "category2" => 1], query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
  end

  def test_post_where_not
    product1 = create(:product, price: 100, category: "category1")
    product2 = create(:product, price: 200, category: "category2")
    product3 = create(:product, price: 300, category: "category1")

    ProductIndex.import [product1, product2, product3]

    query1 = ProductIndex.aggregate(:category).post_where_not(price: 250 .. 350)
    query2 = query1.post_where_not(category: "category2")

    assert_includes query1.records, product1
    assert_includes query1.records, product2
    refute_includes query1.records, product3

    assert_includes query2.records, product1
    refute_includes query2.records, product2
    refute_includes query2.records, product3

    assert_equal Hash["category1" => 2, "category2" => 1], query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
    assert_equal Hash["category1" => 2, "category2" => 1], query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
  end

  def test_post_where_not_with_array
    expected = create(:product, title: "expected", category: "category1")
    rejected1 = create(:product, title: "rejected1", category: "category2")
    rejected2 = create(:product, title: "rejected2", category: "category1")

    ProductIndex.import [expected, rejected1, rejected2]

    query = ProductIndex.aggregate(:category).post_where_not(title: ["rejected1", "rejected2"])

    assert_includes query.records, expected
    refute_includes query.records, rejected1
    refute_includes query.records, rejected2

    assert_equal Hash["category1" => 2, "category2" => 1], query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
  end

  def test_post_where_not_with_range
    expected = create(:product, price: 100, category: "category1")
    rejected1 = create(:product, price: 200, category: "category2")
    rejected2 = create(:product, price: 300, category: "category1")

    ProductIndex.import [expected, rejected1, rejected2]

    query = ProductIndex.aggregate(:category).post_where_not(price: 200 .. 300)

    assert_includes query.records, expected
    refute_includes query.records, rejected1
    refute_includes query.records, rejected2

    assert_equal Hash["category1" => 2, "category2" => 1], query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
  end

  def test_post_filter
    product1 = create(:product, price: 100, category: "category1")
    product2 = create(:product, price: 200, category: "category2")
    product3 = create(:product, price: 300, category: "category1")

    ProductIndex.import [product1, product2, product3]

    query1 = ProductIndex.aggregate(:category).post_filter(range: { price: { gte: 100, lte: 200 }})
    query2 = query1.post_filter(term: { category: "category1" })

    assert_includes query1.records, product1
    assert_includes query1.records, product2
    refute_includes query1.records, product3

    assert_includes query2.records, product1
    refute_includes query2.records, product2
    refute_includes query2.records, product3

    assert_equal Hash["category1" => 2, "category2" => 1], query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
    assert_equal Hash["category1" => 2, "category2" => 1], query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
  end

  def test_post_range
    product1 = create(:product, price: 100, category: "category1")
    product2 = create(:product, price: 200, category: "category2")
    product3 = create(:product, price: 300, category: "category1")

    ProductIndex.import [product1, product2, product3]

    query1 = ProductIndex.aggregate(:category).post_range(:price, gte: 100, lte: 200)
    query2 = query1.post_range(:price, gte: 200, lte: 300)

    assert_includes query1.records, product1
    assert_includes query1.records, product2
    refute_includes query1.records, product3

    refute_includes query2.records, product1
    assert_includes query2.records, product2
    refute_includes query2.records, product3

    assert_equal Hash["category1" => 2, "category2" => 1], query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
    assert_equal Hash["category1" => 2, "category2" => 1], query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
  end

  def test_post_exists
    product1 = create(:product, title: "title1", description: "description1", category: "category1")
    product2 = create(:product, title: "title2", description: nil, category: "category2")
    product3 = create(:product, title: nil, description: "description2", category: "category1")

    ProductIndex.import [product1, product2, product3]

    query1 = ProductIndex.aggregate(:category).post_exists(:title)
    query2 = query1.post_exists(:description)

    assert_includes query1.records, product1
    assert_includes query1.records, product2
    refute_includes query1.records, product3

    assert_includes query2.records, product1
    refute_includes query2.records, product2
    refute_includes query2.records, product3

    assert_equal Hash["category1" => 2, "category2" => 1], query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
    assert_equal Hash["category1" => 2, "category2" => 1], query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
  end

  def test_post_exists_not
    product1 = create(:product, title: nil, description: nil, category: "category1")
    product2 = create(:product, title: nil, description: "description2", category: "category2")
    product3 = create(:product, title: "title3", description: "description3", category: "category1")

    ProductIndex.import [product1, product2, product3]

    query1 = ProductIndex.aggregate(:category).post_exists_not(:title)
    query2 = query1.post_exists_not(:description)

    assert_includes query1.records, product1
    assert_includes query1.records, product2
    refute_includes query1.records, product3

    assert_includes query2.records, product1
    refute_includes query2.records, product2
    refute_includes query2.records, product3

    assert_equal Hash["category1" => 2, "category2" => 1], query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
    assert_equal Hash["category1" => 2, "category2" => 1], query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
  end

  def test_aggregate
    ProductIndex.import create_list(:product, 3, category: "category1", price: 10)
    ProductIndex.import create_list(:product, 2, category: "category2", price: 20)
    ProductIndex.import create_list(:product, 1, category: "category3", price: 30)

    query = ProductIndex.aggregate(:category, size: 2).aggregate(price_sum: { sum: { field: "price" }})

    category_aggregations = query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
    price_aggregation = query.aggregations(:price_sum).value

    assert_equal Hash["category1" => 3, "category2" => 2], category_aggregations
    assert_equal 100, price_aggregation
  end

  def test_aggregate_with_hash
    ProductIndex.import create_list(:product, 3, category: "category1")
    ProductIndex.import create_list(:product, 2, category: "category2")
    ProductIndex.import create_list(:product, 1, category: "category3")

    aggregations = ProductIndex.aggregate(category: { terms: { field: :category }}).aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }

    assert_equal Hash["category1" => 3, "category2" => 2, "category3" => 1], aggregations
  end

  def test_aggregate_with_subaggregation
    ProductIndex.import create_list(:product, 3, category: "category1", price: 15)
    ProductIndex.import create_list(:product, 2, category: "category2", price: 20)
    ProductIndex.import create_list(:product, 1, category: "category3", price: 25)

    query = ProductIndex.aggregate(:category) do |aggregation|
      aggregation.aggregate(price_sum: { sum: { field: "price" }})
    end

    category_aggregations = query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
    price_sum_aggregations = query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.price_sum.value }

    assert_equal Hash["category1" => 3, "category2" => 2, "category3" => 1], category_aggregations
    assert_equal Hash["category1" => 45, "category2" => 40, "category3" => 25], price_sum_aggregations
  end

  def test_profile
    return if ElasticSearch.version.to_i < 2

    assert_not_nil ProductIndex.profile(true).raw_response["profile"]
  end

  def test_scroll
    products = create_list(:product, 15)

    ProductIndex.import products

    relation = ProductIndex.limit(10).scroll(timeout: "1m")

    result = []
    iterations = 0

    until relation.records.empty?
      result += relation.records
      iterations += 1

      relation = relation.scroll(id: relation.scroll_id, timeout: "1m")
    end

    assert_equal result.to_set, products.to_set
    assert_equal 2, iterations
  end

  def test_delete
    product1, product2, product3 = create_list(:product, 3)

    ProductIndex.import [product1, product2, product3]

    assert_difference "ProductIndex.total_entries", -2 do
      ProductIndex.where(id: [product1.id, product2.id]).delete
    end
  end

  def test_source
    product = create(:product, title: "Title", price: 10)

    ProductIndex.import product

    results = ProductIndex.where(id: product.id).results

    assert_present results.first.id
    assert_equal "Title", results.first.title
    assert_equal 10, results.first.price

    results = ProductIndex.where(id: product.id).source([:id, :price]).results

    assert_present results.first.id
    assert_blank results.first.title
    assert_present results.first.price
  end

  def test_includes
    user = create(:user)
    comments = create_list(:comment, 2)
    product = create(:product, user: user, comments: comments)

    ProductIndex.import product

    record = ProductIndex.includes(:user).includes(:comments).records.first

    assert_not_nil record
    assert_equal user, record.user
    assert_equal comments.to_set, record.comments.to_set
  end

  def test_eager_load
    user = create(:user)
    comments = create_list(:comment, 2)
    product = create(:product, user: user, comments: comments)

    ProductIndex.import product

    record = ProductIndex.eager_load(:user).eager_load(:comments).records.first

    assert_not_nil record
    assert_equal user, record.user
    assert_equal comments.to_set, record.comments.to_set
  end

  def test_preload
    user = create(:user)
    comments = create_list(:comment, 2)
    product = create(:product, user: user, comments: comments)

    ProductIndex.import product

    record = ProductIndex.preload(:user).preload(:comments).records.first

    assert_not_nil record
    assert_equal user, record.user
    assert_equal comments.to_set, record.comments.to_set
  end

  def test_sort
    product1 = create(:product, rank: 2, price: 100)
    product2 = create(:product, rank: 2, price: 90)
    product3 = create(:product, rank: 1, price: 120)
    product4 = create(:product, rank: 0, price: 110)

    ProductIndex.import [product1, product2, product3, product4]

    assert_equal [product2, product1, product3, product4], ProductIndex.sort({ rank: :desc }, { price: :asc }).records
    assert_equal [product2, product1, product3, product4], ProductIndex.sort(rank: :desc).sort(:price).records
    assert_equal [product2, product1, product4, product3], ProductIndex.sort(:price).sort(rank: :desc).records
  end

  def test_resort
    product1 = create(:product, rank: 2, price: 100)
    product2 = create(:product, rank: 2, price: 90)
    product3 = create(:product, rank: 1, price: 120)
    product4 = create(:product, rank: 0, price: 110)

    ProductIndex.import [product1, product2, product3, product4]

    assert_equal [product2, product1, product3, product4], ProductIndex.sort(:price).resort({ rank: :desc }, { price: :asc }).records
    assert_equal [product2, product1, product4, product3], ProductIndex.sort(rank: :desc).resort(:price).records
  end

  def test_offset
    product1 = create(:product, rank: 1)
    product2 = create(:product, rank: 2)
    product3 = create(:product, rank: 3)

    ProductIndex.import [product1, product2, product3]

    query = ProductIndex.sort(:rank).offset(1)

    assert_equal [product2, product3], query.records
    assert_equal [product3], query.offset(2).records
  end

  def test_limit
    product1 = create(:product, rank: 1)
    product2 = create(:product, rank: 2)
    product3 = create(:product, rank: 3)

    ProductIndex.import [product1, product2, product3]

    query = ProductIndex.sort(:rank).limit(1)

    assert_equal [product1], query.records
    assert_equal [product1, product2], query.limit(2).records
  end

  def test_paginate
    product1 = create(:product, rank: 1)
    product2 = create(:product, rank: 2)
    product3 = create(:product, rank: 3)

    ProductIndex.import [product1, product2, product3]

    query = ProductIndex.sort(:rank).paginate(page: 1, per_page: 2)

    assert_equal [product1, product2], query.records
    assert_equal [product3], query.paginate(page: 2, per_page: 2).records
  end

  def test_page
    assert_equal 0, ProductIndex.page(1).offset_value
    assert_equal 30, ProductIndex.page(2).offset_value
    assert_equal 100, ProductIndex.page(3).per(50).offset_value
  end

  def test_per
    assert_equal 50, ProductIndex.per(50).limit_value
  end

  def test_search
    product1 = create(:product, title: "Title1", description: "Description1", price: 10)
    product2 = create(:product, title: "Title2", description: "Description2", price: 20)
    product3 = create(:product, title: "Title3", description: "Description2", price: 30)

    ProductIndex.import [product1, product2, product3]

    assert_equal [product1, product3].to_set, ProductIndex.search("Title1 OR Title3").records.to_set
    assert_equal [product1, product3].to_set, ProductIndex.search("Title1 Title3", default_operator: :OR).records.to_set
    assert_equal [product1], ProductIndex.search("Title1 OR Title2").search("Title1 OR Title3").records
    assert_equal [product1], ProductIndex.search("Title1 OR Title3").where(price: 5 .. 15).records
  end

  def test_unscope
    product1 = create(:product, title: "Title1", description: "Description1", price: 10)
    product2 = create(:product, title: "Title2", description: "Description2", price: 20)
    product3 = create(:product, title: "Title3", description: "Description2", price: 30)

    ProductIndex.import [product1, product2, product3]

    assert_equal [product1], ProductIndex.search("Title1 OR Title2").search("Title1 OR Title3").records
    assert_equal [product1, product3].to_set, ProductIndex.search("Title1 OR Title2").unscope(:search).search("Title1 OR Title3").records.to_set
  end

  def test_highlight
    product1 = create(:product, title: "Title1 highlight", description: "Description1 highlight")
    product2 = create(:product, title: "Title2 highlight", description: "Description2 highlight")

    ProductIndex.import [product1, product2]

    results = ProductIndex.sort(:id).highlight([:title, :description]).search("title:highlight description:highlight").results

    assert_equal ["Title1 <em>highlight</em>"], results[0].highlight.title
    assert_equal ["Description1 <em>highlight</em>"], results[0].highlight.description

    assert_equal ["Title2 <em>highlight</em>"], results[1].highlight.title
    assert_equal ["Description2 <em>highlight</em>"], results[1].highlight.description

    results = ProductIndex.sort(:id).highlight([:title, :description], require_field_match: false).search("highlight").results

    assert_equal ["Title1 <em>highlight</em>"], results[0].highlight.title
    assert_equal ["Description1 <em>highlight</em>"], results[0].highlight.description

    assert_equal ["Title2 <em>highlight</em>"], results[1].highlight.title
    assert_equal ["Description2 <em>highlight</em>"], results[1].highlight.description

    results = ProductIndex.sort(:id).highlight(:title, require_field_match: true).highlight(:description, require_field_match: true).search("title:highlight").results

    assert_equal ["Title1 <em>highlight</em>"], results[0].highlight.title
    assert_nil results[0].highlight.description

    assert_equal ["Title2 <em>highlight</em>"], results[1].highlight.title
    assert_nil results[1].highlight.description
  end

  def test_suggest
    product = create(:product, title: "Title", description: "Description")

    ProductIndex.import product

    assert_equal "description", ProductIndex.suggest(:suggestion, text: "Desciption", term: { field: "description" }).suggestions(:suggestion).first["text"]
  end

  def test_find_in_batches
    expected1 = create(:product, title: "expected", rank: 1)
    expected2 = create(:product, title: "expected", rank: 2)
    expected3 = create(:product, title: "expected", rank: 3)
    rejected = create(:product, title: "rejected")

    create :product, title: "rejected"

    ProductIndex.import [expected1, expected2, expected3, rejected]

    assert_equal [[expected1, expected2], [expected3]], ProductIndex.where(title: "expected").sort(:rank).find_in_batches(batch_size: 2).to_a
  end

  def test_find_each
    expected1 = create(:product, title: "expected", rank: 1)
    expected2 = create(:product, title: "expected", rank: 2)
    expected3 = create(:product, title: "expected", rank: 3)
    rejected = create(:product, title: "rejected")

    create :product, title: "rejected"

    ProductIndex.import [expected1, expected2, expected3, rejected]

    assert_equal [expected1, expected2, expected3], ProductIndex.where(title: "expected").sort(:rank).find_each(batch_size: 2).to_a
  end

  def test_failsafe
    assert_raises ElasticSearch::ResponseError do
      ProductIndex.search("syntax/error").records
    end

    query = ProductIndex.failsafe(true).search("syntax/error")

    assert_equal [], query.records
    assert_equal 0, query.total_entries
  end

  def test_fresh
    create :product

    query = ProductIndex.relation.tap(&:records)

    assert_not_nil query.instance_variable_get(:@response)

    refute query.fresh === query
    assert_nil query.fresh.instance_variable_get(:@response)
  end

  def test_respond_to?
    temp_index = Class.new(ProductIndex)

    refute temp_index.relation.respond_to?(:test_scope)

    temp_index.scope(:test_scope) { match_all }

    assert temp_index.relation.respond_to?(:test_scope)
  end

  def test_method_missing
    temp_index = Class.new(ProductIndex)

    expected = create(:product, title: "expected")
    rejected = create(:product, title: "rejected")

    temp_index.import [expected, rejected]

    temp_index.scope(:with_title) { |title| where(title: title) }

    records = temp_index.relation.with_title("expected").records

    assert_includes records, expected
    refute_includes records, rejected
  end

  def test_custom
    request = ProductIndex.custom(custom_key: "custom_value").request

    assert_equal "custom_value", request[:custom_key]
  end
end

