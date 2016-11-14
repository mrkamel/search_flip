
require File.expand_path("../test_helper", __FILE__)

class IndexTest < ElasticSearch::TestCase
  should_delegate_methods :profile, :where, :where_not, :filter, :range, :match_all, :exists, :exists_not, :post_where,
    :post_where_not, :post_filter, :post_range, :post_exists, :post_exists_not, :aggregate, :facet, :scroll, :source,
    :includes, :eager_load, :preload, :sort, :order, :offset, :limit, :paginate, :query, :search, :find_in_batches,
    :find_each, :failsafe, :total_entries, :to => :relation, subject: ProductIndex

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
    assert_difference "ProductIndex.total_entries" do
      ProductIndex.import create(:product)

      assert ProductIndex.refresh
    end
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

    ElasticSearch::Config[:index_prefix] = nil
  end

  def test_type_url
    assert_equal "http://127.0.0.1:9200/products/products", ProductIndex.type_url

    ProductIndex.stubs(:type_name).returns("products2")

    assert_equal "http://127.0.0.1:9200/products2/products2", ProductIndex.type_url
  end

  def test_import_array
    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.import [create(:product), create(:product)]
    end
  end

  def test_import_scope
    create_list :product, 2

    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.import Product.all
    end
  end

  def test_import_with_param_options
    products = create_list(:product, 2)

    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.import products, {}, version: 1, version_type: "external"
    end

    assert_no_difference "ProductIndex.total_entries" do
      ProductIndex.import products, {}, version: 2, version_type: "external"
      ProductIndex.import products, { ignore_errors: [409] }, version: 2, version_type: "external"

      assert_raises ElasticSearch::Bulk::Error do
        ProductIndex.import products, {}, version: 2, version_type: "external"
      end
    end
  end

  def test_import_with_class_options
    products = create_list(:product, 2)

    ProductIndex.stubs(:index_options).returns(version: 3, version_type: "external")

    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.import products
    end

    assert_equal [3, 3], products.map { |product| ProductIndex.get(product.id)["_version"] }
  end

  def test_index
    # Already tested
  end

  def test_create_array
    products = create_list(:product, 2)

    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.create products
    end

    assert_no_difference "ProductIndex.total_entries" do
      assert_raises ElasticSearch::Bulk::Error do
        ProductIndex.create products
      end
    end
  end

  def test_create_scope
    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.create create_list(:product, 2)
    end
  end

  def test_create_with_param_options
    products = create_list(:product, 2)

    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.create products
    end

    assert_no_difference "ProductIndex.total_entries" do
      ProductIndex.create products, :ignore_errors => [409]
    end

    products = create_list(:product, 2)

    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.create products, {}, version: 1, version_type: "external"
    end

    assert_no_difference "ProductIndex.total_entries" do
      assert_raises ElasticSearch::Bulk::Error do
        ProductIndex.import products, {}, version: 1, version_type: "external"
      end
    end
  end

  def test_create_with_class_options
    products = create_list(:product, 2)

    ProductIndex.stubs(:index_options).returns(version: 2, version_type: "external")

    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.create products
    end

    assert_equal [2, 2], products.map { |product| ProductIndex.get(product.id)["_version"] }
  end

  def test_create_already_created
    products = create_list(:product, 2)

    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.create products
    end

    assert_raises ElasticSearch::Bulk::Error do
      ProductIndex.create products
    end
  end

  def test_get
    # Already tested
  end
end

