require File.expand_path("../spec_helper", __dir__)

RSpec.describe SearchFlip::Aggregation do
  describe "#where" do
    it "sets up the constraints correctly for the aggregation and is chainable" do
      product1 = create(:product, category: "category1", title: "title", description: "description")
      product2 = create(:product, category: "category2", title: "title", description: "description")
      product3 = create(:product, category: "category1", title: "title", description: "description")
      product4 = create(:product, category: "category2", title: "title", description: "other")
      product5 = create(:product, category: "category1", title: "other", description: "description")

      ProductIndex.import [product1, product2, product3, product4, product5]

      query = ProductIndex.aggregate(category: {}) do |aggregation|
        aggregation.where(title: "title").where(description: "description").aggregate(:category)
      end

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }

      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end

    it "works with arrays" do
      product1 = create(:product, category: "category1", title: "title1", description: "description1")
      product2 = create(:product, category: "category2", title: "title2", description: "description2")
      product3 = create(:product, category: "category1", title: "title3", description: "description3")
      product4 = create(:product, category: "category2", title: "title4", description: "other")
      product5 = create(:product, category: "category1", title: "other", description: "description")

      ProductIndex.import [product1, product2, product3, product4, product5]

      query = ProductIndex.aggregate(category: {}) do |aggregation|
        aggregation
          .where(title: ["title1", "title2", "title3", "title4"])
          .where(description: ["description1", "description2", "description3"])
          .aggregate(:category)
      end

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }

      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end

    it "works with ranges" do
      product1 = create(:product, category: "category1", title: "title1", price: 100)
      product2 = create(:product, category: "category2", title: "title2", price: 150)
      product3 = create(:product, category: "category1", title: "title3", price: 200)
      product4 = create(:product, category: "category2", title: "title4", price: 250)
      product5 = create(:product, category: "category1", title: "other", price: 200)

      ProductIndex.import [product1, product2, product3, product4, product5]

      query = ProductIndex.aggregate(category: {}) do |aggregation|
        aggregation.where(title: "title1".."title3").where(price: 100..200).aggregate(:category)
      end

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }

      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end
  end

  describe "#where_not" do
    it "sets up the constraints correctly for the aggregation and is chainable" do
      product1 = create(:product, category: "category1", title: "title1")
      product2 = create(:product, category: "category2", title: "title2")
      product3 = create(:product, category: "category1", title: "title3")
      product4 = create(:product, category: "category2", title: "title4")
      product5 = create(:product, category: "category1", title: "title5")

      ProductIndex.import [product1, product2, product3, product4, product5]

      query = ProductIndex.aggregate(category: {}) do |aggregation|
        aggregation.where_not(title: "title4").where_not(title: "title5").aggregate(:category)
      end

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }

      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end

    it "works with arrays" do
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

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }

      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end

    it "works with ranges" do
      product1 = create(:product, category: "category1", title: "title1", price: 100)
      product2 = create(:product, category: "category2", title: "title2", price: 150)
      product3 = create(:product, category: "category1", title: "title3", price: 200)
      product4 = create(:product, category: "category2", title: "title4", price: 250)
      product5 = create(:product, category: "category1", title: "title5", price: 300)
      product6 = create(:product, category: "category2", title: "title6", price: 350)
      product7 = create(:product, category: "category1", title: "title7", price: 400)

      ProductIndex.import [product1, product2, product3, product4, product5, product6, product7]

      query = ProductIndex.aggregate(category: {}) do |aggregation|
        aggregation.where_not(price: 100..150).where_not(title: "title6".."title7").aggregate(:category)
      end

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }

      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end
  end

  describe "#filter" do
    it "sets up the constraints correctly for the aggregation and is chainable" do
      product1 = create(:product, category: "category1", title: "title", price: 100)
      product2 = create(:product, category: "category2", title: "title", price: 150)
      product3 = create(:product, category: "category1", title: "title", price: 200)
      product4 = create(:product, category: "category2", title: "other", price: 200)
      product5 = create(:product, category: "category1", title: "title", price: 250)

      ProductIndex.import [product1, product2, product3, product4, product5]

      query = ProductIndex.aggregate(category: {}) do |aggregation|
        aggregation.filter(range: { price: { gte: 100, lte: 200 } }).filter(term: { title: "title" }).aggregate(:category)
      end

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }

      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end
  end

  describe "#range" do
    it "sets up the constraints correctly for the aggregation and is chainable" do
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

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }

      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end
  end

  describe "#match_all" do
    it "sets up the constraints correctly for the aggregation and is chainable" do
      product1 = create(:product, category: "category1")
      product2 = create(:product, category: "category2")
      product3 = create(:product, category: "category1")

      ProductIndex.import [product1, product2, product3]

      query = ProductIndex.aggregate(category: {}) do |aggregation|
        aggregation.match_all.aggregate(:category)
      end

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }

      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end
  end

  describe "#exists" do
    it "sets up the constraints correctly for the aggregation and is chainable" do
      product1 = create(:product, category: "category1", title: "title1", price: 10)
      product2 = create(:product, category: "category2", title: "title2")
      product3 = create(:product, category: "category1", title: "title3", price: 20)
      product4 = create(:product, category: "category2", title: "title4", price: 30)
      product5 = create(:product, category: "category1", price: 40)

      ProductIndex.import [product1, product2, product3, product4, product5]

      query = ProductIndex.aggregate(category: {}) do |aggregation|
        aggregation.exists(:title).exists(:price).aggregate(:category)
      end

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }

      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end
  end

  describe "#exists_not" do
    it "sets up the constraints correctly for the aggregation and is chainable" do
      product1 = create(:product, category: "category1")
      product2 = create(:product, category: "category2", title: "title2")
      product3 = create(:product, category: "category1")
      product4 = create(:product, category: "category2")
      product5 = create(:product, category: "category1", price: 40)

      ProductIndex.import [product1, product2, product3, product4, product5]

      query = ProductIndex.aggregate(category: {}) do |aggregation|
        aggregation.exists_not(:title).exists_not(:price).aggregate(:category)
      end

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket[:key]] = bucket.doc_count }

      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end
  end

  describe "#aggregate" do
    it "aggregates within an aggregation" do
      product1 = create(:product, category: "category1", title: "title1", price: 10)
      product2 = create(:product, category: "category1", title: "title2", price: 15)
      product3 = create(:product, category: "category1", title: "title1", price: 20)
      product4 = create(:product, category: "category2", title: "title2", price: 25)
      product5 = create(:product, category: "category2", title: "title1", price: 30)
      product6 = create(:product, category: "category2", title: "title2", price: 35)

      ProductIndex.import [product1, product2, product3, product4, product5, product6]

      query = ProductIndex.aggregate(:category) do |aggregation|
        aggregation.aggregate(:title) do |aggregation2|
          aggregation2.aggregate(price: { sum: { field: "price" } })
        end
      end

      aggregations = query.aggregations(:category).each_with_object({}) do |(key, agg), hash|
        hash[key] = agg.doc_count
      end

      expect(aggregations).to eq("category1" => 3, "category2" => 3)

      aggregations = query.aggregations(:category)["category1"].title.buckets.each_with_object({}) do |bucket, hash|
        hash[bucket[:key]] = bucket.doc_count
      end

      expect(aggregations).to eq("title1" => 2, "title2" => 1)

      aggregations = query.aggregations(:category)["category2"].title.buckets.each_with_object({}) do |bucket, hash|
        hash[bucket[:key]] = bucket.doc_count
      end

      expect(aggregations).to eq("title1" => 1, "title2" => 2)

      expect(query.aggregations(:category)["category1"].title.buckets.detect { |bucket| bucket[:key] == "title1" }.price.value).to eq(30)
      expect(query.aggregations(:category)["category1"].title.buckets.detect { |bucket| bucket[:key] == "title2" }.price.value).to eq(15)
      expect(query.aggregations(:category)["category2"].title.buckets.detect { |bucket| bucket[:key] == "title1" }.price.value).to eq(30)
      expect(query.aggregations(:category)["category2"].title.buckets.detect { |bucket| bucket[:key] == "title2" }.price.value).to eq(60)
    end
  end

  describe "#merge" do
    it "merges a criteria into the aggregation" do
      product1 = create(:product, price: 100, category: "category1")
      product2 = create(:product, price: 150, category: "category1")
      product3 = create(:product, price: 200, category: "category2")
      product4 = create(:product, price: 300, category: "category1")

      ProductIndex.import [product1, product2, product3, product4]

      query = ProductIndex.aggregate(categories: {}) do |agg|
        agg.merge(ProductIndex.where(price: 100..200)).aggregate(:category)
      end

      result = query.aggregations(:categories).category.buckets.each_with_object({}) do |bucket, hash|
        hash[bucket["key"]] = bucket.doc_count
      end

      expect(result).to eq("category1" => 2, "category2" => 1)
    end

    describe "unsupported methods" do
      unsupported_methods = [
        :profile_value, :failsafe_value, :terminate_after_value, :timeout_value, :offset_value, :limit_value,
        :scroll_args, :highlight_values, :suggest_values, :custom_value, :source_value, :sort_values,
        :includes_values, :preload_values, :eager_load_values, :post_must_values,
        :post_must_not_values, :post_filter_values, :preference_value,
        :search_type_value, :routing_value
      ]

      unsupported_methods.each do |unsupported_method|
        it "raises a NotSupportedError #{unsupported_method}" do
          block = lambda do
            TestIndex.aggregate(field: {}) do |agg|
              criteria = SearchFlip::Criteria.new(target: TestIndex)
              criteria.send("#{unsupported_method}=", "value")

              agg.merge(criteria)
            end
          end

          expect(&block).to raise_error(SearchFlip::NotSupportedError)
        end
      end
    end

    describe "array concatenations" do
      methods = [:must_values, :must_not_values, :filter_values]

      methods.each do |method|
        it "concatenates the values for #{method}" do
          aggregation = SearchFlip::Aggregation.new(target: TestIndex)
          aggregation.send("#{method}=", ["value1"])

          criteria = SearchFlip::Criteria.new(target: TestIndex)
          criteria.send("#{method}=", ["value2"])

          result = aggregation.merge(criteria)

          expect(result.send(method)).to eq(["value1", "value2"])
        end
      end
    end

    describe "hash merges" do
      methods = [:aggregation_values]

      methods.each do |method|
        it "merges the values for #{method}" do
          aggregation = SearchFlip::Aggregation.new(target: TestIndex)
          aggregation.send("#{method}=", key1: "value1")

          criteria = SearchFlip::Criteria.new(target: TestIndex)
          criteria.send("#{method}=", key2: "value2")

          result = aggregation.merge(criteria)

          expect(result.send(method)).to eq(key1: "value1", key2: "value2")
        end
      end
    end
  end

  describe "#respond_to?" do
    it "checks whether or not the index class responds to the method" do
      temp_index = Class.new(ProductIndex)
      aggregation = SearchFlip::Aggregation.new(target: temp_index)

      expect(aggregation.respond_to?(:test_scope)).to eq(false)

      temp_index.scope(:test_scope) { match_all }

      expect(aggregation.respond_to?(:test_scope)).to eq(true)
    end
  end

  describe "#method_missing" do
    it "delegates to the index class" do
      temp_index = Class.new(ProductIndex)
      temp_index.scope(:with_price_range) { |range| where(price: range) }

      product1 = create(:product, price: 100, category: "category1")
      product2 = create(:product, price: 150, category: "category1")
      product3 = create(:product, price: 200, category: "category2")
      product4 = create(:product, price: 300, category: "category1")

      temp_index.import [product1, product2, product3, product4]

      query = temp_index.aggregate(categories: {}) do |agg|
        agg.merge(temp_index.with_price_range(100..200)).aggregate(:category)
      end

      result = query.aggregations(:categories).category.buckets.each_with_object({}) do |bucket, hash|
        hash[bucket["key"]] = bucket.doc_count
      end

      expect(result).to eq("category1" => 2, "category2" => 1)
    end
  end
end
