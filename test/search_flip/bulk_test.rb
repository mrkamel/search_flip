
require File.expand_path("../../test_helper", __FILE__)

class SearchFlip::BulkTest < SearchFlip::TestCase
  def test_bulk
    product1, product2 = create_list(:product, 2)

    assert_difference "ProductIndex.total_entries", 2 do
      ProductIndex.bulk do |bulk|
        bulk.create product1.id, SearchFlip::JSON.generate(ProductIndex.serialize(product1))
        bulk.create product2.id, SearchFlip::JSON.generate(ProductIndex.serialize(product1))
      end
    end

    assert_difference "ProductIndex.total_entries", -2 do
      ProductIndex.bulk do |bulk|
        bulk.delete product1.id
        bulk.delete product2.id
      end
    end
  end

  def test_bulk_with_options
    product1, product2 = create_list(:product, 2)

    ProductIndex.import [product1, product2]

    assert_raises "SearchFlip::Bulk::Error" do
      ProductIndex.bulk do |bulk|
        bulk.create product1.id, SearchFlip::JSON.generate(ProductIndex.serialize(product1))
        bulk.create product2.id, SearchFlip::JSON.generate(ProductIndex.serialize(product1))
      end
    end

    ProductIndex.bulk(ignore_errors: [409]) do |bulk|
      bulk.create product1.id, SearchFlip::JSON.generate(ProductIndex.serialize(product1))
      bulk.create product2.id, SearchFlip::JSON.generate(ProductIndex.serialize(product1))
    end
  end

  def test_bulk_with_item_options
    product = create(:product)

    ProductIndex.bulk do |bulk|
      bulk.index product.id, SearchFlip::JSON.generate(ProductIndex.serialize(product)), version: 1, version_type: "external_gt"
    end

    assert_raises "SearchFlip::Bulk::Error" do
      ProductIndex.bulk do |bulk|
        bulk.index product.id, SearchFlip::JSON.generate(ProductIndex.serialize(product)), version: 1, version_type: "external_gt"
      end
    end
  end
end

