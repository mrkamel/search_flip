
require File.expand_path("../../test_helper", __FILE__)

class SearchFlip::AggregationRelationTest < SearchFlip::TestCase
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
    product1 = create(:product, category: "category1", title: "title1")
    product2 = create(:product, category: "category2", title: "title2")
    product3 = create(:product, category: "category1", title: "title3")
    product4 = create(:product, category: "category2", title: "title4")
    product5 = create(:product, category: "category1", title: "title5")

    ProductIndex.import [product1, product2, product3, product4, product5]

    query = ProductIndex.aggregate(category: {}) do |aggregation|
      aggregation.where_not(title: "title4").where_not(title: "title5").aggregate(:category)
    end

    assert_equal Hash["category1" => 2, "category2" => 1], query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }
  end

  def test_where_not_with_array
    product1 = create(:product, category: "category1", title: "title1")
    product2 = create(:product, category: "category2", title: "title2")
    product3 = create(:product, category: "category1", title: "title3")
    product4 = create(:product, category: "category2", title: "title4")
    product5 = create(:product, category: "category1", title: "title5")
    product6 = create(:product, category: "category2", title: "title6")
    product7 = create(:product, category: "category1", title: "title7")

    ProductIndex.import [product1, product2, product3, product4, product5, product6, product7]

    query = ProductIndex.aggregate(category: {}) do |aggregation|
      aggregation.where_not(title: ["title1", "title2"]).where_not(title: ["title6", "title7"]).aggregate(:category)
    end

    assert_equal Hash["category1" => 2, "category2" => 1], query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }
  end

  def test_where_not_with_range
    product1 = create(:product, category: "category1", title: "title1", price: 100)
    product2 = create(:product, category: "category2", title: "title2", price: 150)
    product3 = create(:product, category: "category1", title: "title3", price: 200)
    product4 = create(:product, category: "category2", title: "title4", price: 250)
    product5 = create(:product, category: "category1", title: "title5", price: 300)
    product6 = create(:product, category: "category2", title: "title6", price: 350)
    product7 = create(:product, category: "category1", title: "title7", price: 400)

    ProductIndex.import [product1, product2, product3, product4, product5, product6, product7]

    query = ProductIndex.aggregate(category: {}) do |aggregation|
      aggregation.where_not(price: 100 .. 150).where_not(title: "title6" .. "title7").aggregate(:category)
    end

    assert_equal Hash["category1" => 2, "category2" => 1], query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }
  end

  def test_filter
    product1 = create(:product, category: "category1", title: "title", price: 100)
    product2 = create(:product, category: "category2", title: "title", price: 150)
    product3 = create(:product, category: "category1", title: "title", price: 200)
    product4 = create(:product, category: "category2", title: "other", price: 200)
    product5 = create(:product, category: "category1", title: "title", price: 250)

    ProductIndex.import [product1, product2, product3, product4, product5]

    query = ProductIndex.aggregate(category: {}) do |aggregation|
      aggregation.filter(range: { price: { gte: 100, lte: 200 }}).filter(term: { title: "title" }).aggregate(:category)
    end

    assert_equal Hash["category1" => 2, "category2" => 1], query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }
  end

  def test_range
    product1 = create(:product, category: "category1", title: "title1", price: 100)
    product2 = create(:product, category: "category2", title: "title2", price: 150)
    product3 = create(:product, category: "category1", title: "title3", price: 200)
    product4 = create(:product, category: "category2", title: "title4", price: 250)
    product5 = create(:product, category: "category1", title: "title5", price: 300)
    product6 = create(:product, category: "category2", title: "title6", price: 350)
    product7 = create(:product, category: "category1", title: "title7", price: 400)

    ProductIndex.import [product1, product2, product3, product4, product5, product6, product7]

    query = ProductIndex.aggregate(category: {}) do |aggregation|
      aggregation.range(:price, gte: 100, lte: 200).range(:title, gte: "title1", lte: "title3").aggregate(:category)
    end

    assert_equal Hash["category1" => 2, "category2" => 1], query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }
  end

  def test_match_all
    product1 = create(:product, category: "category1")
    product2 = create(:product, category: "category2")
    product3 = create(:product, category: "category1")

    ProductIndex.import [product1, product2, product3]

    query = ProductIndex.aggregate(category: {}) do |aggregation|
      aggregation.match_all.aggregate(:category)
    end

    assert_equal Hash["category1" => 2, "category2" => 1], query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }
  end

  def test_exists
    product1 = create(:product, category: "category1", title: "title1", price: 10)
    product2 = create(:product, category: "category2", title: "title2")
    product3 = create(:product, category: "category1", title: "title3", price: 20)
    product4 = create(:product, category: "category2", title: "title4", price: 30)
    product5 = create(:product, category: "category1", price: 40)

    ProductIndex.import [product1, product2, product3, product4, product5]

    query = ProductIndex.aggregate(category: {}) do |aggregation|
      aggregation.exists(:title).exists(:price).aggregate(:category)
    end

    assert_equal Hash["category1" => 2, "category2" => 1], query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }
  end

  def test_exists_not
    product1 = create(:product, category: "category1")
    product2 = create(:product, category: "category2", title: "title2")
    product3 = create(:product, category: "category1")
    product4 = create(:product, category: "category2")
    product5 = create(:product, category: "category1", price: 40)

    ProductIndex.import [product1, product2, product3, product4, product5]

    query = ProductIndex.aggregate(category: {}) do |aggregation|
      aggregation.exists_not(:title).exists_not(:price).aggregate(:category)
    end

    assert_equal Hash["category1" => 2, "category2" => 1], query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }
  end

  def test_aggregate
    product1 = create(:product, category: "category1", title: "title1", price: 10)
    product2 = create(:product, category: "category1", title: "title2", price: 15)
    product3 = create(:product, category: "category1", title: "title1", price: 20)
    product4 = create(:product, category: "category2", title: "title2", price: 25)
    product5 = create(:product, category: "category2", title: "title1", price: 30)
    product6 = create(:product, category: "category2", title: "title2", price: 35)

    ProductIndex.import [product1, product2, product3, product4, product5, product6]

    query = ProductIndex.aggregate(:category) do |aggregation|
      aggregation.aggregate(:title) do |_aggregation|
        _aggregation.aggregate(price: { sum: { field: "price" }})
      end
    end

    assert_equal Hash["category1" => 3, "category2" => 3], query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }

    assert_equal Hash["title1" => 2, "title2" => 1], query.aggregations(:category)["category1"].title.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }
    assert_equal Hash["title1" => 1, "title2" => 2], query.aggregations(:category)["category2"].title.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }

    assert_equal 30, query.aggregations(:category)["category1"].title.buckets.detect { |bucket| bucket[:key] == "title1" }.price.value
    assert_equal 15, query.aggregations(:category)["category1"].title.buckets.detect { |bucket| bucket[:key] == "title2" }.price.value
    assert_equal 30, query.aggregations(:category)["category2"].title.buckets.detect { |bucket| bucket[:key] == "title1" }.price.value
    assert_equal 60, query.aggregations(:category)["category2"].title.buckets.detect { |bucket| bucket[:key] == "title2" }.price.value
  end
end

