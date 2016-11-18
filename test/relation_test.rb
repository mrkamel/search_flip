
require File.expand_path("../test_helper", __FILE__)

class IndexTest < ElasticSearch::TestCase
  should_delegate_methods :total_entries, :current_page, :previous_page, :next_page, :total_pages, :hits, :ids,
    :count, :size, :length, :took, :aggregations, :scope, :results, :records, :scroll_id, to: :response,
    subject: ElasticSearch::Relation.new(:target => ProductIndex)

  def test_where_chain
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

  def test_where_not_chain
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

  def test_filter_chain
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

  def test_range_chain
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

  def test_exists_chain
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
  end

  def test_post_where_not
  end

  def test_post_filter
  end

  def test_post_range
  end

  def test_post_exists
  end

  def test_pot_exists_not
  end

  def test_aggregate
  end

  def test_profile
  end

  def test_scroll
  end

  def test_delete
  end

  def test_source
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

