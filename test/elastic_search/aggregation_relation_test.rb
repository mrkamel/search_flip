
require File.expand_path("../../test_helper", __FILE__)

class ElasticSearch::AggregationRelationTest < ElasticSearch::TestCase
  def test_where
    product1 = create(:product, category: "category1", title: "title", description: "description")
    product2 = create(:product, category: "category2", title: "title", description: "description")
    product3 = create(:product, category: "category1", title: "title", description: "description")
    product4 = create(:product, category: "category2", title: "title", description: "other")
    product5 = create(:product, category: "category1", title: "other", description: "description")

    ProductIndex.import [product1, product2, product3, product4, product5]

    query = ProductIndex.aggregate(category: {}) do |aggregation|
      aggregation.where(title: "title").where(description: "description").aggregate(:category)
    end

    assert_equal Hash["category1" => 2, "category2" => 1], query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }
  end

  def test_where_with_array
    product1 = create(:product, category: "category1", title: "title1", description: "description1")
    product2 = create(:product, category: "category2", title: "title2", description: "description2")
    product3 = create(:product, category: "category1", title: "title3", description: "description3")
    product4 = create(:product, category: "category2", title: "title4", description: "other")
    product5 = create(:product, category: "category1", title: "other", description: "description")

    ProductIndex.import [product1, product2, product3, product4, product5]

    query = ProductIndex.aggregate(category: {}) do |aggregation|
      aggregation.where(title: ["title1", "title2", "title3", "title4"]).where(description: ["description1", "description2", "description3"]).aggregate(:category)
    end

    assert_equal Hash["category1" => 2, "category2" => 1], query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }
  end

  def test_where_with_range
    product1 = create(:product, category: "category1", title: "title1", price: 100)
    product2 = create(:product, category: "category2", title: "title2", price: 150)
    product3 = create(:product, category: "category1", title: "title3", price: 200)
    product4 = create(:product, category: "category2", title: "title4", price: 250)
    product5 = create(:product, category: "category1", title: "other", price: 200)

    ProductIndex.import [product1, product2, product3, product4, product5]

    query = ProductIndex.aggregate(category: {}) do |aggregation|
      aggregation.where(title: "title1" .. "title3").where(price: 100 .. 200).aggregate(:category)
    end

    assert_equal Hash["category1" => 2, "category2" => 1], query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }
  end

  def test_where_not
  end

  def test_where_not_with_array
  end

  def test_where_not_with_range
  end

  def test_filter
  end

  def test_range
  end

  def test_match_all
  end

  def test_exists
  end

  def test_exists_not
  end

  def test_aggregate
  end
end

