
require File.expand_path("../spec_helper", __dir__)

RSpec.describe SearchFlip::Bulk do
  describe "#bulk" do
    it "uses bulk mode" do
      product1, product2 = create_list(:product, 2)

      expect(ProductIndex.total_count).to eq(0)

      ProductIndex.bulk do |bulk|
        bulk.create product1.id, ProductIndex.serialize(product1)
        bulk.create product2.id, ProductIndex.serialize(product1)
      end

      expect(ProductIndex.total_count).to eq(2)

      ProductIndex.bulk do |bulk|
        bulk.delete product1.id
        bulk.delete product2.id
      end

      expect(ProductIndex.total_count).to eq(0)
    end

    it "accepts and passes options" do
      product1, product2 = create_list(:product, 2)

      ProductIndex.import [product1, product2]

      block = lambda do
        ProductIndex.bulk do |bulk|
          bulk.create product1.id, ProductIndex.serialize(product1)
          bulk.create product2.id, ProductIndex.serialize(product1)
        end
      end

      expect(&block).to raise_error(SearchFlip::Bulk::Error)

      ProductIndex.bulk(ignore_errors: [409]) do |bulk|
        bulk.create product1.id, ProductIndex.serialize(product1)
        bulk.create product2.id, ProductIndex.serialize(product1)
      end
    end

    it "accepts and passes item options" do
      product = create(:product)

      ProductIndex.bulk do |bulk|
        bulk.index product.id, ProductIndex.serialize(product), version: 1, version_type: "external_gt"
      end

      block = lambda do
        ProductIndex.bulk do |bulk|
          bulk.index product.id, ProductIndex.serialize(product), version: 1, version_type: "external_gt"
        end
      end

      expect(&block).to raise_error(SearchFlip::Bulk::Error)
    end

    it "uses the specified http_client" do
      product = create(:product)

      stub_request(:put, "#{ProductIndex.type_url}/_bulk?filter_path=errors")
        .with(headers: { "X-Header" => "Value" })
        .to_return(status: 500)

      block = lambda do
        ProductIndex.bulk http_client: ProductIndex.connection.http_client.headers("X-Header" => "Value") do |bulk|
          bulk.index product.id, ProductIndex.serialize(product)
        end
      end

      expect(&block).to raise_error(SearchFlip::ResponseError)
    end

    it "handles overly long payloads" do
      product = create(:product)

      allow(product).to receive(:description).and_return("x" * 1024 * 1024 * 10)

      block = lambda do
        ProductIndex.bulk bulk_max_mb: 1_000 do |bulk|
          100.times do
            bulk.index product.id, ProductIndex.serialize(product)
          end
        end
      end

      expect(&block).to raise_error(SearchFlip::ResponseError)

      block = lambda do
        ProductIndex.bulk bulk_max_mb: 100 do |bulk|
          100.times do
            bulk.index product.id, ProductIndex.serialize(product)
          end
        end
      end

      expect(&block).not_to raise_error #(SearchFlip::ResponseError)
    end
  end
end
