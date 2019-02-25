
require File.expand_path("../test_helper", __dir__)

class SearchFlip::IndexTest < SearchFlip::TestCase
  should_delegate_methods :profile, :where, :where_not, :filter, :range, :match_all, :exists,
    :exists_not, :post_where, :post_where_not, :post_filter, :post_must, :post_must_not,
    :post_should, :post_range, :post_exists, :post_exists_not, :aggregate, :scroll, :source,
    :includes, :eager_load, :preload, :sort, :resort, :order, :reorder, :offset, :limit,
    :paginate, :page, :per, :search, :find_in_batches, :highlight, :suggest, :custom, :find_each,
    :failsafe, :total_entries, :total_count, :terminate_after, :timeout, :should, :should_not,
    :must, :must_not, to: :criteria, subject: ProductIndex

  def test_serialize_exception
    klass = Class.new do
      include SearchFlip::Index
    end

    assert_raises SearchFlip::MethodNotImplemented do
      klass.serialize(Hashie::Mash)
    end
  end

  def test_type_name_exception
    klass = Class.new do
      include SearchFlip::Index
    end

    assert_raises SearchFlip::MethodNotImplemented do
      klass.serialize(Hashie::Mash)
    end
  end

  def test_create_index_works
    assert TestIndex.create_index
  ensure
    TestIndex.delete_index if TestIndex.index_exists?
  end

  def test_create_index_delegates_to_connection
    TestIndex.connection.expects(:create_index).with("test", {})
    TestIndex.create_index
  end

  def test_create_index_passes_index_settings_to_connection
    TestIndex.stubs(:index_settings).returns(settings: { number_of_shards: 3 })
    assert TestIndex.create_index

    assert "3", TestIndex.get_index_settings["test"]["settings"]["index"]["number_of_replicas"]
  ensure
    TestIndex.delete_index if TestIndex.index_exists?
  end

  def test_create_index_passes_index_settings_delegates_to_connection
    TestIndex.stubs(:index_settings).returns(settings: { number_of_shards: 3 })

    TestIndex.connection.expects(:create_index).with("test", settings: { number_of_shards: 3 })
    TestIndex.create_index
  end

  def test_create_index_passes_mapping_if_specified
    TestIndex.stubs(:mapping).returns(test: { properties: { id: { type: "long" } } })
    assert TestIndex.create_index
  ensure
    TestIndex.delete_index if TestIndex.index_exists?
  end

  def test_create_index_passes_mapping_if_specified_delegates_to_connection
    TestIndex.stubs(:mapping).returns(test: { properties: { id: { type: "long" } } })

    TestIndex.connection.expects(:create_index).with("test", mappings: { test: { properties: { id: { type: "long" } } } })
    TestIndex.create_index(include_mapping: true)
  end

  def test_update_index_settings_works
    TestIndex.create_index
    TestIndex.stubs(:index_settings).returns(settings: { number_of_replicas: 3 })
    TestIndex.update_index_settings
  ensure
    TestIndex.delete_index if TestIndex.index_exists?
  end

  def test_update_index_settings_delegates_to_connection
    index_settings = { settings: { number_of_replicas: 3 } }

    TestIndex.stubs(:index_settings).returns(settings: { number_of_replicas: 3 })

    TestIndex.connection.expects(:update_index_settings).with("test", index_settings)
    TestIndex.update_index_settings
  end

  def test_get_index_settings_works
    TestIndex.create_index
    assert TestIndex.get_index_settings
  ensure
    TestIndex.delete_index if TestIndex.index_exists?
  end

  def test_get_index_settings_delegates_to_connection
    TestIndex.connection.expects(:get_index_settings).with("test")
    TestIndex.get_index_settings
  end

  def test_index_exists_works
    TestIndex.create_index
    assert TestIndex.index_exists?
  ensure
    TestIndex.delete_index if TestIndex.index_exists?
  end

  def test_index_exists_delegates_to_connection
    TestIndex.connection.expects(:index_exists?).with("test")
    TestIndex.index_exists?
  end

  def test_delete_index_works
    TestIndex.create_index
    assert TestIndex.delete_index
  ensure
    TestIndex.delete_index if TestIndex.index_exists?
  end

  def test_delete_index_delegates_to_connection
    TestIndex.connection.expects(:delete_index).with("test")
    TestIndex.delete_index
  end

  def test_update_mapping_works
    TestIndex.stubs(:mapping).returns(test: { properties: { id: { type: "long" } } })

    TestIndex.create_index
    TestIndex.update_mapping
  ensure
    TestIndex.delete_index if TestIndex.index_exists?
  end

  def test_update_mapping_delegates_to_connection
    mapping = { test: { properties: { id: { type: "long" } } } }

    TestIndex.stubs(:mapping).returns(mapping)

    TestIndex.connection.expects(:update_mapping).with("test", "test", mapping)
    TestIndex.update_mapping
  end

  def test_get_mapping_works
    TestIndex.create_index
    TestIndex.update_mapping

    assert TestIndex.get_mapping
  ensure
    TestIndex.delete_index if TestIndex.index_exists?
  end

  def test_get_mapping_delegates_to_connection
    TestIndex.connection.expects(:get_mapping).with("test", "test")
    TestIndex.get_mapping
  end

  def test_refresh_works
    TestIndex.create_index
    TestIndex.refresh
  ensure
    TestIndex.delete_index if TestIndex.index_exists?
  end

  def test_refresh_delegates_to_connection
    TestIndex.connection.expects(:refresh).with("test")
    TestIndex.refresh
  end

  def test_index_url
    assert TestIndex.index_url
  end

  def test_index_url_delegates_to_connection
    TestIndex.connection.expects(:index_url).with("test")
    TestIndex.index_url

    SearchFlip::Config[:index_prefix] = "prefix-"
    TestIndex.connection.expects(:index_url).with("prefix-test")
    TestIndex.index_url
  ensure
    SearchFlip::Config[:index_prefix] = nil
  end

  def test_type_url
    assert TestIndex.type_url
  end

  def test_type_url_delegates_to_connection
    TestIndex.connection.expects(:type_url).with("test", "test")
    TestIndex.type_url
  end

  def test_import_object
    assert_difference "ProductIndex.total_entries" do
      ProductIndex.import create(:product)
    end
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

      assert_raises SearchFlip::Bulk::Error do
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

    actual = products.map { |product| ProductIndex.get(product.id)["_version"] }

    assert_equal [3, 3], actual
  end

  def test_index_array
    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.index create_list(:product, 2)
    end
  end

  def test_index_scope
    temp_product_index = Class.new(ProductIndex)

    temp_product_index.define_singleton_method(:index_scope) do |scope|
      scope.where("price < 80")
    end

    products = [create(:product, price: 20), create(:product, price: 50), create(:product, price: 100)]

    assert_difference "ProductIndex.total_entries", 2 do
      temp_product_index.index Product.where(id: products.map(&:id))
    end
  end

  def test_create_array
    products = create_list(:product, 2)

    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.create products
    end

    assert_no_difference "ProductIndex.total_entries" do
      assert_raises SearchFlip::Bulk::Error do
        ProductIndex.create products
      end
    end
  end

  def test_create_scope
    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.create Product.where(id: create_list(:product, 2).map(&:id))
    end
  end

  def test_update_array
    products = create_list(:product, 2)

    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.import products
    end

    assert_no_difference "ProductIndex.total_entries" do
      ProductIndex.update products
    end
  end

  def test_update_scope
    products = create_list(:product, 2)

    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.import products
    end

    assert_no_difference "ProductIndex.total_entries" do
      ProductIndex.update Product.where(id: products.map(&:id))
    end
  end

  def test_delete_array
    products = create_list(:product, 2)

    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.import products
    end

    assert_difference "ProductIndex.total_entries", -2 do
      ProductIndex.delete products
    end
  end

  def test_delete_scope
    products = create_list(:product, 2)

    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.import products
    end

    assert_difference "ProductIndex.total_entries", -2 do
      ProductIndex.delete Product.where(id: Product.where(id: products.map(&:id)))
    end
  end

  def test_create_already_created
    products = create_list(:product, 2)

    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.create products
    end

    assert_raises SearchFlip::Bulk::Error do
      ProductIndex.create products
    end
  end

  def test_create_with_param_options
    products = create_list(:product, 2)

    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.create products
    end

    assert_no_difference "ProductIndex.total_entries" do
      ProductIndex.create products, ignore_errors: [409]
    end

    products = create_list(:product, 2)

    if ProductIndex.connection.version.to_i >= 5
      assert_difference "ProductIndex.total_entries", 2 do
        ProductIndex.create products, {}, routing: "r1"
      end

      actual = ProductIndex.get(products.first.id, routing: "r1")["_routing"]

      assert_equal "r1", actual
    else
      assert_difference "ProductIndex.total_entries", 2 do
        ProductIndex.create products, {}, version: 2, version_type: "external"
      end

      actual = products.map { |product| ProductIndex.get(product.id)["_version"] }

      assert_equal [2, 2], actual
    end
  end

  def test_create_with_class_options
    products = create_list(:product, 2)

    if ProductIndex.connection.version.to_i >= 5
      ProductIndex.stubs(:index_options).returns(routing: "r1")

      assert_difference "ProductIndex.total_entries", 2 do
        ProductIndex.create products
      end

      actual = products.map { |product| ProductIndex.get(product.id, routing: "r1")["_routing"] }

      assert_equal ["r1", "r1"], actual
    else
      ProductIndex.stubs(:index_options).returns(version: 2, version_type: "external")

      assert_difference "ProductIndex.total_entries", 2 do
        ProductIndex.create products
      end

      actual = products.map { |product| ProductIndex.get(product.id)["_version"] }

      assert_equal [2, 2], actual
    end
  end

  def test_get
    # Already tested
  end

  def test_scope
    temp_product_index = Class.new(ProductIndex)

    temp_product_index.scope(:with_title) { |title| where(title: title) }

    expected = create(:product, title: "expected")
    rejected = create(:product, title: "rejected")

    temp_product_index.import [expected, rejected]

    results = temp_product_index.with_title("expected").records

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_bulk
    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.bulk do |indexer|
        indexer.index 1, id: 1
        indexer.index 2, id: 2
      end
    end

    assert_no_difference "ProductIndex.total_entries" do
      assert_raises "SearchFlip::Bulk::Error" do
        ProductIndex.bulk do |indexer|
          indexer.index 1, { id: 1 }, version: 1, version_type: "external"
          indexer.index 2, { id: 2 }, version: 1, version_type: "external"
        end
      end

      ProductIndex.bulk ignore_errors: [409] do |indexer|
        indexer.index 1, { id: 1 }, version: 1, version_type: "external"
        indexer.index 2, { id: 2 }, version: 1, version_type: "external"
      end
    end
  end

  def test_connection
    assert_equal "http://127.0.0.1:9200", ProductIndex.connection.base_url
  end
end

