require File.expand_path("../spec_helper", __dir__)

RSpec.describe SearchFlip::Response do
  describe "#total_count" do
    it "returns the number of results" do
      ProductIndex.import create_list(:product, 3)

      expect(ProductIndex.total_count).to eq(3)
      expect(ProductIndex.total_entries).to eq(3)
    end
  end

  describe "#current_page" do
    it "returns the current page number" do
      ProductIndex.import create_list(:product, 3)

      expect(ProductIndex.paginate(page: 1, per_page: 2).current_page).to eq(1)
      expect(ProductIndex.paginate(page: 2, per_page: 2).current_page).to eq(2)
      expect(ProductIndex.paginate(page: 3, per_page: 2).current_page).to eq(3)
    end
  end

  describe "#total_pages" do
    it "returns the number of total pages" do
      expect(ProductIndex.paginate(page: 1, per_page: 2).total_pages).to eq(1)

      ProductIndex.import create_list(:product, 3)

      expect(ProductIndex.paginate(page: 1, per_page: 2).total_pages).to eq(2)
    end
  end

  describe "#previous_page" do
    it "returns the previous page number" do
      ProductIndex.import create_list(:product, 3)

      expect(ProductIndex.paginate(page: 1, per_page: 2).previous_page).to be_nil
      expect(ProductIndex.paginate(page: 2, per_page: 2).previous_page).to eq(1)
      expect(ProductIndex.paginate(page: 3, per_page: 2).previous_page).to eq(2)
    end
  end

  describe "#next_page" do
    it "returns the next page number" do
      ProductIndex.import create_list(:product, 3)

      expect(ProductIndex.paginate(page: 1, per_page: 2).next_page).to eq(2)
      expect(ProductIndex.paginate(page: 2, per_page: 2).next_page).to be_nil
    end
  end

  describe "#first_page?" do
    it "returns whether or not the current page is the first page" do
      ProductIndex.import create(:product)

      expect(ProductIndex.paginate(page: 1).first_page?).to eq(true)
      expect(ProductIndex.paginate(page: 2).first_page?).to eq(false)
    end
  end

  describe "#last_page?" do
    it "returns whether or not the current page is the last page" do
      ProductIndex.import create_list(:product, 31)

      expect(ProductIndex.paginate(page: 2).last_page?).to eq(true)
      expect(ProductIndex.paginate(page: 1).last_page?).to eq(false)
    end
  end

  describe "#out_of_range?" do
    it "returns whether or not the current page is out of range" do
      ProductIndex.import create(:product)

      expect(ProductIndex.paginate(page: 2).out_of_range?).to eq(true)
      expect(ProductIndex.paginate(page: 1).out_of_range?).to eq(false)
    end
  end

  describe "#results" do
    it "returns the current results" do
      products = create_list(:product, 3)

      ProductIndex.import products

      expect(ProductIndex.match_all.results.map(&:id).to_set).to eq(products.map(&:id).to_set)
    end
  end

  describe "#hits" do
    it "returns the current hits" do
      ProductIndex.import create_list(:product, 3)

      response = ProductIndex.match_all.response

      expect(response.hits).to be_present
      expect(response.hits).to eq(response.raw_response["hits"])
    end
  end

  describe "#scroll_id" do
    it "returns the current scroll id" do
      ProductIndex.import create_list(:product, 3)

      response = ProductIndex.scroll.response

      expect(response.scroll_id).to be_present
      expect(response.scroll_id).to eq(response.raw_response["_scroll_id"])
    end
  end

  describe "#records" do
    it "returns the records for the current hits" do
      products = create_list(:product, 3)

      ProductIndex.import products

      expect(ProductIndex.match_all.records.to_set).to eq(products.to_set)
    end
  end

  describe "#ids" do
    it "returns the ids for the current hits" do
      products = create_list(:product, 3)

      ProductIndex.import products

      response = ProductIndex.match_all.response

      expect(response.ids.to_set).to eq(products.map(&:id).map(&:to_s).to_set)
      expect(response.ids).to eq(response.raw_response["hits"]["hits"].map { |hit| hit["_id"] })
    end
  end

  describe "#took" do
    it "returns the took value" do
      ProductIndex.import create_list(:product, 3)

      response = ProductIndex.match_all.response

      expect(response.took).to be_present
      expect(response.took).to eq(response.raw_response["took"])
    end
  end

  describe "#aggregations" do
    it "returns a convenient version of the aggregations" do
      product1 = create(:product, price: 10, category: "category1")
      product2 = create(:product, price: 20, category: "category2")
      product3 = create(:product, price: 30, category: "category1")

      ProductIndex.import [product1, product2, product3]

      query = ProductIndex.aggregate(:category) do |aggregation|
        aggregation.aggregate(price_sum: { sum: { field: "price" } })
      end

      aggregations = query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)

      expect(query.aggregations(:category)["category1"].price_sum.value).to eq(40)
      expect(query.aggregations(:category)["category2"].price_sum.value).to eq(20)
    end

    it "returns the raw aggregations if no key is specified" do
      product1 = create(:product, category: "category1")
      product2 = create(:product, category: "category2")
      product3 = create(:product, category: "category1")

      ProductIndex.import [product1, product2, product3]

      query = ProductIndex.aggregate(:category)

      expected = [
        { "doc_count" => 2, "key" => "category1" },
        { "doc_count" => 1, "key" => "category2" }
      ]

      expect(query.aggregations["category"]["buckets"]).to eq(expected)
    end
  end
end
