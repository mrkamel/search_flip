
require File.expand_path("../test_helper", __FILE__)

class IndexTest < ElasticSearch::TestCase
  should_delegate_methods :profile, :where, :where_not, :filter, :range, :match_all, :exists, :exists_not, :post_where,
    :post_where_not, :post_filter, :post_range, :post_exists, :post_exists_not, :aggregate, :facet, :scroll, :source,
    :includes, :eager_load, :preload, :sort, :order, :offset, :limit, :paginate, :query, :search, :find_in_batches,
    :find_each, :failsafe, :total_entries, :to => :relation, :subject => ProductIndex

  def test_create_index
    assert TestIndex.create_index
    assert TestIndex.index_exists?

    TestIndex.delete_index

    refute TestIndex.index_exists?
  end

  def test_index_exists?
    # Already tested
  end

  def test_delete_index
    TestIndex.create_index

    assert TestIndex.index_exists?
    assert TestIndex.delete_index

    refute TestIndex.index_exists?
  end

  def test_update_mapping
    TestIndex.create_index
    TestIndex.update_mapping

    mapping = TestIndex.get_mapping

    assert mapping["test"]["mappings"]["test"]["properties"]["test_field"]

    TestIndex.delete_index
  end

  def test_get_mapping
    # Aready tested
  end

  def test_refresh
    ProductIndex.import create(:product)

    assert ProductIndex.refresh

    assert_equal 1, ProductIndex.total_entries
  end

  def test_base_url
    assert_equal "http://127.0.0.1:9200", ProductIndex.base_url
  end

  def test_index_url
    assert_equal "http://127.0.0.1:9200/products", ProductIndex.index_url

    ProductIndex.stubs(:type_name).returns("products2")

    assert_equal "http://127.0.0.1:9200/products2", ProductIndex.index_url

    ElasticSearch::Config[:index_prefix] = "prefix-"

    assert_equal "http://127.0.0.1:9200/prefix-products2", ProductIndex.index_url

    ProductIndex.stubs(:index_name).returns("products3")

    assert_equal "http://127.0.0.1:9200/prefix-products3", ProductIndex.index_url
  end

  def test_type_url
    assert_equal "http://127.0.0.1:9200/products/products", ProductIndex.type_url

    ProductIndex.stubs(:type_name).returns("products2")

    assert_equal "http://127.0.0.1:9200/products2/products2", ProductIndex.type_url
  end
end

