
require File.expand_path("../spec_helper", __dir__)

RSpec.describe SearchFlip::Index do
  describe "delegation" do
    subject { ProductIndex }

    methods = [
      :profile, :where, :where_not, :filter, :range, :match_all, :exists,
      :exists_not, :post_where, :post_where_not, :post_filter, :post_must,
      :post_must_not, :post_should, :post_range, :post_exists, :post_exists_not,
      :aggregate, :scroll, :source, :includes, :eager_load, :preload, :sort, :resort,
      :order, :reorder, :offset, :limit, :paginate, :page, :per, :search,
      :find_in_batches, :highlight, :suggest, :custom, :find_each, :failsafe,
      :total_entries, :total_count, :terminate_after, :timeout, :records, :results,
      :should, :should_not, :must, :must_not, :find_each_result,
      :find_results_in_batches, :preference, :search_type, :routing
    ]

    methods.each do |method|
      it { should delegate(method).to(:criteria) }
    end
  end

  describe ".serialize" do
    it "raises a SearchFlip::MethodNotImplemented by default" do
      klass = Class.new do
        include SearchFlip::Index
      end

      expect { klass.serialize(Object.new) }.to raise_error(SearchFlip::MethodNotImplemented)
    end
  end

  describe ".type_name" do
    it "raises a SearchFlip::MethodNotImplemented by default" do
      klass = Class.new do
        include SearchFlip::Index
      end

      expect { klass.type_name }.to raise_error(SearchFlip::MethodNotImplemented)
    end
  end

  describe ".type_name" do
    it "raises a SearchFlip::MethodNotImplemented by default" do
      klass = Class.new do
        include SearchFlip::Index
      end

      expect { klass.index_name }.to raise_error(SearchFlip::MethodNotImplemented)
    end
  end

  describe ".create_index" do
    it "delegates to connection" do
      allow(TestIndex.connection).to receive(:create_index).and_call_original

      TestIndex.create_index

      expect(TestIndex.connection).to have_received(:create_index).with("test", {})
    end

    it "includes the mapping if specified" do
      mapping = { test: { properties: { id: { type: "long" } } } }

      allow(TestIndex).to receive(:mapping).and_return(mapping)
      allow(TestIndex.connection).to receive(:create_index).and_call_original

      TestIndex.create_index(include_mapping: true)

      expect(TestIndex.connection).to have_received(:create_index).with("test", mappings: mapping)
    end

    it "includes the index settings" do
      allow(TestIndex).to receive(:index_settings).and_return(number_of_shards: 2)
      allow(TestIndex.connection).to receive(:create_index).and_call_original

      TestIndex.create_index

      expect(TestIndex.connection).to have_received(:create_index).with("test", number_of_shards: 2)
    end
  end

  describe ".index_exists?" do
    it "delegates to connection" do
      TestIndex.create_index

      allow(TestIndex.connection).to receive(:index_exists?).and_call_original

      TestIndex.index_exists?

      expect(TestIndex.connection).to have_received(:index_exists?).with("test")
    end
  end

  describe ".delete_index" do
    it "delegates to connection" do
      TestIndex.create_index

      expect(TestIndex.index_exists?).to eq(true)

      allow(TestIndex.connection).to receive(:delete_index).and_call_original

      TestIndex.delete_index

      expect(TestIndex.index_exists?).to eq(false)
    end
  end

  describe ".get_index_settings" do
    it "delegates to connection" do
      TestIndex.create_index

      allow(TestIndex.connection).to receive(:get_index_settings).and_call_original

      TestIndex.get_index_settings

      expect(TestIndex.connection).to have_received(:get_index_settings).with("test")
    end
  end

  describe ".update_index_settings" do
    it "delegates to connection" do
      TestIndex.create_index

      allow(TestIndex).to receive(:index_settings).and_return(number_of_replicas: 3)
      allow(TestIndex.connection).to receive(:update_index_settings).and_call_original

      TestIndex.update_index_settings

      expect(TestIndex.connection).to have_received(:update_index_settings).with("test", number_of_replicas: 3)
    end
  end

  describe ".update_mapping" do
    it "delegates to connection" do
      TestIndex.create_index

      mapping = { test: { properties: { id: { type: "long" } } } }

      allow(TestIndex).to receive(:mapping).and_return(mapping)
      allow(TestIndex.connection).to receive(:update_mapping).and_call_original

      TestIndex.update_mapping

      expect(TestIndex.connection).to have_received(:update_mapping).with("test", "test", mapping)
    end
  end

  describe ".get_mapping" do
    it "delegates to connection" do
      TestIndex.create_index
      TestIndex.update_mapping

      allow(TestIndex.connection).to receive(:get_mapping).and_call_original

      TestIndex.get_mapping

      expect(TestIndex.connection).to have_received(:get_mapping).with("test", "test")
    end
  end

  describe ".refresh" do
    it "delegates to connection" do
      TestIndex.create_index

      allow(TestIndex.connection).to receive(:refresh).and_call_original

      TestIndex.refresh

      expect(TestIndex.connection).to have_received(:refresh).with("test")
    end
  end

  describe ".index_url" do
    it "delegates to connection" do
      allow(TestIndex.connection).to receive(:index_url).and_call_original

      TestIndex.index_url

      expect(TestIndex.connection).to have_received(:index_url).with("test")
    end

    it "includes the index prefix" do
      begin
        SearchFlip::Config[:index_prefix] = "prefix-"

        allow(TestIndex.connection).to receive(:index_url).and_call_original

        TestIndex.index_url

        expect(TestIndex.connection).to have_received(:index_url).with("prefix-test")
      ensure
        SearchFlip::Config[:index_prefix] = nil
      end
    end
  end

  describe ".type_url" do
    it "delegates to connection" do
      allow(TestIndex.connection).to receive(:type_url).and_call_original

      TestIndex.type_url

      expect(TestIndex.connection).to have_received(:type_url).with("test", "test")
    end
  end

  describe ".import" do
    it "imports an object" do
      expect { ProductIndex.import create(:product) }.to(change { ProductIndex.total_count }.by(1))
    end

    it "imports an array of objects" do
      expect { ProductIndex.import [create(:product), create(:product)] }.to(change { ProductIndex.total_count }.by(2))
    end

    it "imports a scope" do
      create_list :product, 2

      expect { ProductIndex.import Product.all }.to(change { ProductIndex.total_count }.by(2))
    end

    it "allows param options" do
      products = create_list(:product, 2)

      expect { ProductIndex.import products, {}, version: 1, version_type: "external" }.to(change { ProductIndex.total_count }.by(2))
      expect { ProductIndex.import products, {}, version: 2, version_type: "external" }.not_to(change { ProductIndex.total_count })
      expect { ProductIndex.import products, { ignore_errors: [409] }, version: 2, version_type: "external" }.not_to(change { ProductIndex.total_count })
      expect { ProductIndex.import products, {}, version: 2, version_type: "external" }.to raise_error(SearchFlip::Bulk::Error)
    end

    it "passes param options" do
      product = create(:product)

      ProductIndex.import product, {}, version: 10, version_type: "external"

      expect(ProductIndex.get(product.id)["_version"]).to eq(10)
    end

    it "passes class options" do
      product = create(:product)

      allow(ProductIndex).to receive(:index_options).and_return(version: 10, version_type: "external")

      ProductIndex.import product

      expect(ProductIndex.get(product.id)["_version"]).to eq(10)
    end
  end

  describe ".index" do
    it "indexes an object" do
      expect { ProductIndex.index create(:product) }.to(change { ProductIndex.total_count }.by(1))
    end

    it "indexes an array of objects" do
      expect { ProductIndex.index [create(:product), create(:product)] }.to(change { ProductIndex.total_count }.by(2))
    end

    it "indexes a scope" do
      create_list :product, 2

      expect { ProductIndex.index Product.all }.to(change { ProductIndex.total_count }.by(2))
    end
  end

  describe ".create" do
    it "creates an object" do
      product = create(:product)

      expect { ProductIndex.create product }.to(change { ProductIndex.total_count }.by(1))
      expect { ProductIndex.create product }.to raise_error(SearchFlip::Bulk::Error)
    end

    it "create an array of objects" do
      products = create_list(:product, 2)

      expect { ProductIndex.create products }.to(change { ProductIndex.total_count }.by(2))
      expect { ProductIndex.create products }.to raise_error(SearchFlip::Bulk::Error)
    end

    it "creates a scope of objects" do
      create_list(:product, 2)

      expect { ProductIndex.create Product.all }.to(change { ProductIndex.total_count }.by(2))
      expect { ProductIndex.create Product.all }.to raise_error(SearchFlip::Bulk::Error)
    end

    it "allows respects param options" do
      products = create_list(:product, 2)

      expect { ProductIndex.create products }.to(change { ProductIndex.total_count }.by(2))
      expect { ProductIndex.create products, ignore_errors: [409] }.not_to(change { ProductIndex.total_count })

      products = create_list(:product, 2)

      if ProductIndex.connection.version.to_i >= 5
        expect { ProductIndex.create products, {}, routing: "r1" }.to(change { ProductIndex.total_count }.by(2))

        expect(ProductIndex.get(products.first.id, routing: "r1")["_routing"]).to eq("r1")
      else
        expect { ProductIndex.create products, {}, version: 2, version_type: "external" }.to(change { ProductIndex.total_count }.by(2))

        expect(ProductIndex.get(products.first.id)["_version"]).to eq(2)
      end
    end

    it "allows respects class options" do
      products = create_list(:product, 2)

      if ProductIndex.connection.version.to_i >= 5
        allow(ProductIndex).to receive(:index_options).and_return(routing: "r1")

        expect { ProductIndex.create products }.to(change { ProductIndex.total_count }.by(2))

        expect(ProductIndex.get(products.first.id, routing: "r1")["_routing"]).to eq("r1")
      else
        allow(ProductIndex).to receive(:index_options).and_return(version: 2, version_type: "external")

        expect { ProductIndex.create products }.to(change { ProductIndex.total_count }.by(2))

        expect(ProductIndex.get(products.first.id)["_version"]).to eq(2)
      end
    end
  end

  describe ".update" do
    it "updates an object" do
      product = create(:product)

      ProductIndex.import product

      expect { ProductIndex.update product }.not_to(change { ProductIndex.total_count })
    end

    it "updates an array of objects" do
      products = create_list(:product, 2)

      ProductIndex.import products

      expect { ProductIndex.update products }.not_to(change { ProductIndex.total_count })
    end

    it "updates a scope of objects" do
      products = create_list(:product, 2)

      ProductIndex.import products

      expect { ProductIndex.update Product.all }.not_to(change { ProductIndex.total_count })
    end
  end

  describe ".delete" do
    it "deletes an object" do
      product = create(:product)

      ProductIndex.import product

      expect { ProductIndex.delete product }.to(change { ProductIndex.total_count }.by(-1))
    end

    it "deletes an array of objects" do
      products = create_list(:product, 2)

      ProductIndex.import products

      expect { ProductIndex.delete products }.to(change { ProductIndex.total_count }.by(-2))
    end

    it "deletes a scope of objects" do
      products = create_list(:product, 2)

      ProductIndex.import products

      expect { ProductIndex.delete Product.all }.to(change { ProductIndex.total_count }.by(-2))
    end
  end

  describe ".get" do
    it "retrieves the document" do
      product = create(:product)

      ProductIndex.import product

      expect(ProductIndex.get(product.id)["_id"]).to eq(product.id.to_s)
    end

    it "passes params" do
      product = create(:product)
      ProductIndex.import product

      expect(ProductIndex.get(product.id).keys).to include("_source")
      expect(ProductIndex.get(product.id, _source: false).keys).not_to include("_source")
    end
  end

  describe ".scope" do
    it "adds a scope" do
      temp_product_index = Class.new(ProductIndex)
      temp_product_index.scope(:with_title) { |title| where(title: title) }

      expected = create(:product, title: "expected")
      rejected = create(:product, title: "rejected")

      temp_product_index.import [expected, rejected]

      results = temp_product_index.with_title("expected").records

      expect(results).to eq([expected])
    end
  end

  describe ".bulk" do
    it "imports objects" do
      bulk = proc do
        ProductIndex.bulk do |indexer|
          indexer.index 1, id: 1
          indexer.index 2, id: 2
        end
      end

      expect(&bulk).to(change { ProductIndex.total_count }.by(2))
    end

    it "respects options" do
      ProductIndex.bulk do |indexer|
        indexer.index 1, id: 1
        indexer.index 2, id: 2
      end

      bulk = proc do
        ProductIndex.bulk do |indexer|
          indexer.index 1, { id: 1 }, version: 1, version_type: "external"
          indexer.index 2, { id: 2 }, version: 1, version_type: "external"
        end
      end

      expect(&bulk).to raise_error(SearchFlip::Bulk::Error)

      bulk = proc do
        ProductIndex.bulk ignore_errors: [409] do |indexer|
          indexer.index 1, { id: 1 }, version: 1, version_type: "external"
          indexer.index 2, { id: 2 }, version: 1, version_type: "external"
        end
      end

      expect(&bulk).not_to(change { ProductIndex.total_count })
    end

    it "passes default options" do
      allow(SearchFlip::Bulk).to receive(:new)

      ProductIndex.bulk do |indexer|
        indexer.index 1, id: 1
      end

      connection = ProductIndex.connection

      expect(SearchFlip::Bulk).to have_received(:new).with(
        anything,
        http_client: connection.http_client,
        bulk_limit: connection.bulk_limit,
        bulk_max_mb: connection.bulk_max_mb
      )
    end

    it "passes custom options" do
      allow(SearchFlip::Bulk).to receive(:new)

      options = {
        bulk_limit: "bulk limit",
        bulk_max_mb: "bulk max mb",
        http_client: "http client"
      }

      ProductIndex.bulk(options) do |indexer|
        indexer.index 1, id: 1
      end

      expect(SearchFlip::Bulk).to have_received(:new).with(anything, options)
    end
  end

  describe ".connection" do
    it "returns a SearchFlip::Connection" do
      expect(ProductIndex.connection).to be_instance_of(SearchFlip::Connection)
    end

    it "memoizes" do
      connection = ProductIndex.connection

      expect(ProductIndex.connection).to equal(connection)
    end
  end
end

