
require File.expand_path("../../test_helper", __FILE__)

class SearchFlip::ResponseTest < SearchFlip::TestCase
  def test_total_entries
    ProductIndex.import create_list(:product, 3)

    assert_equal 3, ProductIndex.total_entries
  end

  def test_curent_page
    assert_equal 1, ProductIndex.match_all.current_page

    ProductIndex.import create_list(:product, 3)

    assert_equal 1, ProductIndex.paginate(page: 1, per_page: 2).current_page
    assert_equal 2, ProductIndex.paginate(page: 2, per_page: 2).current_page
    assert_equal 3, ProductIndex.paginate(page: 3, per_page: 2).current_page
  end

  def test_total_pages
    assert_equal 1, ProductIndex.paginate(page: 1, per_page: 2).total_pages

    ProductIndex.import create_list(:product, 3)

    assert_equal 2, ProductIndex.paginate(page: 1, per_page: 2).total_pages
  end

  def test_previous_page
    ProductIndex.import create_list(:product, 3)

    assert_nil ProductIndex.paginate(page: 1, per_page: 2).previous_page
    assert_equal 1, ProductIndex.paginate(page: 2, per_page: 2).previous_page
    assert_equal 2, ProductIndex.paginate(page: 3, per_page: 2).previous_page
  end

  def test_next_page
    ProductIndex.import create_list(:product, 3)

    assert_equal 2, ProductIndex.paginate(page: 1, per_page: 2).next_page
    assert_nil ProductIndex.paginate(page: 2, per_page: 2).next_page
  end

  def test_first_page?
    ProductIndex.import create(:product)

    assert ProductIndex.paginate(page: 1).first_page?
    refute ProductIndex.paginate(page: 2).first_page?
  end

  def test_last_page?
    ProductIndex.import create_list(:product, 31)

    assert ProductIndex.paginate(page: 2).last_page?
    refute ProductIndex.paginate(page: 1).last_page?
  end

  def test_out_of_range?
    ProductIndex.import create(:product)

    assert ProductIndex.paginate(page: 2).out_of_range?
    refute ProductIndex.paginate(page: 1).out_of_range?
  end

  def test_results
    products = create_list(:product, 3)

    ProductIndex.import products

    assert_equal products.map(&:id).to_set, ProductIndex.match_all.results.map(&:id).to_set
  end

  def test_hits
    ProductIndex.import create_list(:product, 3)

    response = ProductIndex.match_all.response

    assert_present response.hits
    assert_equal response.raw_response["hits"], response.hits
  end

  def test_scroll_id
    ProductIndex.import create_list(:product, 3)

    response = ProductIndex.scroll.response

    assert_present response.scroll_id
    assert_equal response.raw_response["_scroll_id"], response.scroll_id
  end

  def test_records
    products = create_list(:product, 3)

    ProductIndex.import products

    assert_equal products.to_set, ProductIndex.match_all.records.to_set
  end

  def test_ids
    products = create_list(:product, 3)

    ProductIndex.import products

    response = ProductIndex.match_all.response

    assert_equal products.map(&:id).map(&:to_s).to_set, response.ids.to_set
    assert_equal response.raw_response["hits"]["hits"].map { |hit| hit["_id"] }, response.ids
  end

  def test_took
    ProductIndex.import create_list(:product, 3)

    response = ProductIndex.match_all.response

    assert_present response.took
    assert_equal response.raw_response["took"], response.took
  end

  def test_aggregations
    product1 = create(:product, price: 10, category: "category1")
    product2 = create(:product, price: 20, category: "category2")
    product3 = create(:product, price: 30, category: "category1")

    ProductIndex.import [product1, product2, product3]

    query = ProductIndex.aggregate(:category) do |aggregation|
      aggregation.aggregate(price_sum: { sum: { field: "price" }})
    end

    assert_equal Hash["category1" => 2, "category2" => 1], query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }

    assert_equal 40, query.aggregations(:category)["category1"].price_sum.value
    assert_equal 20, query.aggregations(:category)["category2"].price_sum.value
  end
end

