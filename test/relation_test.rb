
require File.expand_path("../test_helper", __FILE__)

class IndexTest < ElasticSearch::TestCase
  should_delegate_methods :total_entries, :current_page, :previous_page, :next_page, :total_pages, :hits, :ids,
    :count, :size, :length, :took, :aggregations, :scope, :results, :records, :scroll_id, :raw_response,
    to: :response, subject: ElasticSearch::Relation.new(:target => ProductIndex)

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
    refute_nil ProductIndex.profile(true).raw_response["profile"]
  end

  def test_scroll
    products = create_list(:product, 15)

    ProductIndex.import products

    relation = ProductIndex.limit(10).scroll(timeout: "1m")

    result = []
    iterations = 0

    while records = relation.records.presence
      result += records
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
      ProductIndex.where(:id => [product1.id, product2.id]).delete
    end
  end

  def test_source
    product = create(:product, :title => "Title", :price => 10)

    ProductIndex.import product

    results = ProductIndex.where(:id => product.id).results

    assert_present results.first.id
    assert_equal "Title", results.first.title
    assert_equal 10, results.first.price

    results = ProductIndex.where(:id => product.id).source([:id, :price]).results

    assert_present results.first.id
    assert_blank results.first.title
    assert_present results.first.price
  end

  def test_includes
  end

  def test_eager_load
  end

  def test_preload
  end

  def test_sort
  end

  def test_resort
  end

  def test_order
  end

  def test_reorder
  end

  def test_offset
  end

  def test_limit
  end

  def test_paginate
  end

  def test_query
  end

  def test_search
  end

  def test_find_in_batches
  end

  def test_find_each
  end

  def test_failsafe
  end

  def test_fresh
  end

  def test_respond_to?
  end

  def test_method_missing
  end
end

