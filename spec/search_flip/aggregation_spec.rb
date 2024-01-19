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

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket["key"]] = bucket.doc_count }

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

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket["key"]] = bucket.doc_count }

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

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket["key"]] = bucket.doc_count }

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

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket["key"]] = bucket.doc_count }

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

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket["key"]] = bucket.doc_count }

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

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket["key"]] = bucket.doc_count }

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

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket["key"]] = bucket.doc_count }

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

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket["key"]] = bucket.doc_count }

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

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket["key"]] = bucket.doc_count }

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

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket["key"]] = bucket.doc_count }

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

      aggregations = query.aggregations(:category).category.buckets.each_with_object({}) { |bucket, hash| hash[bucket["key"]] = bucket.doc_count }

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
        hash[bucket["key"]] = bucket.doc_count
      end

      expect(aggregations).to eq("title1" => 2, "title2" => 1)

      aggregations = query.aggregations(:category)["category2"].title.buckets.each_with_object({}) do |bucket, hash|
        hash[bucket["key"]] = bucket.doc_count
      end

      expect(aggregations).to eq("title1" => 1, "title2" => 2)

      expect(query.aggregations(:category)["category1"].title.buckets.detect { |bucket| bucket["key"] == "title1" }.price.value).to eq(30)
      expect(query.aggregations(:category)["category1"].title.buckets.detect { |bucket| bucket["key"] == "title2" }.price.value).to eq(15)
      expect(query.aggregations(:category)["category2"].title.buckets.detect { |bucket| bucket["key"] == "title1" }.price.value).to eq(30)
      expect(query.aggregations(:category)["category2"].title.buckets.detect { |bucket| bucket["key"] == "title2" }.price.value).to eq(60)
    end
  end

  describe "#merge" do
    it "merges a criteria into the aggregation" do
      product1 = create(:product, price: 100, category: "category1")
      product2 = create(:product, price: 150, category: "category1")
      product3 = create(:product, price: 200, category: "category2")
      product4 = create(:product, price: 300, category: "category1")

      ProductIndex.import [product1, product2, product3, product4]

      query = ProductIndex.aggregate(categories: {}) do |aggregation|
        aggregation.merge(ProductIndex.where(price: 100..200)).aggregate(:category)
      end

      result = query.aggregations(:categories).category.buckets.each_with_object({}) do |bucket, hash|
        hash[bucket["key"]] = bucket.doc_count
      end

      expect(result).to eq("category1" => 2, "category2" => 1)
    end

    describe "assignments" do
      methods = [:offset_value, :limit_value, :source_value, :explain_value]

      methods.each do |method|
        it "replaces the values" do
          aggregation = SearchFlip::Aggregation.new(target: TestIndex)
          aggregation.send("#{method}=", "value1")

          criteria = SearchFlip::Criteria.new(target: TestIndex)
          criteria.send("#{method}=", "value2")

          expect(aggregation.merge(criteria).send(method)).to eq("value2")
        end
      end
    end

    describe "array concatenations" do
      methods = [:sort_values, :must_values, :must_not_values, :filter_values]

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
      methods = [:highlight_values, :custom_value, :aggregation_values]

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

    describe "unsupported methods" do
      unsupported_methods = [
        :profile_value, :failsafe_value, :terminate_after_value, :timeout_value, :scroll_args,
        :suggest_values, :includes_values, :preload_values, :eager_load_values, :post_must_values,
        :post_must_not_values, :post_filter_values, :preference_value, :search_type_value, :routing_value
      ]

      unsupported_methods.each do |unsupported_method|
        it "raises a NotSupportedError #{unsupported_method}" do
          block = lambda do
            aggregation = SearchFlip::Aggregation.new(target: TestIndex)

            criteria = SearchFlip::Criteria.new(target: TestIndex)
            criteria.send("#{unsupported_method}=", "value")

            aggregation.merge(criteria)
          end

          expect(&block).to raise_error(SearchFlip::NotSupportedError)
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

      query = temp_index.aggregate(categories: {}) do |aggregation|
        aggregation.merge(temp_index.with_price_range(100..200)).aggregate(:category)
      end

      result = query.aggregations(:categories).category.buckets.each_with_object({}) do |bucket, hash|
        hash[bucket["key"]] = bucket.doc_count
      end

      expect(result).to eq("category1" => 2, "category2" => 1)
    end
  end

  describe "#explain" do
    it "returns the explaination" do
      ProductIndex.import create(:product)

      query = ProductIndex.aggregate(top_hits: { top_hits: {} }) do |aggregation|
        aggregation.explain(true)
      end

      expect(query.aggregations("top_hits").hits.hits.first.key?("_explanation")).to eq(true)
    end
  end

  describe "#custom" do
    it "adds a custom entry to the request" do
      query = ProductIndex.aggregate(top_hits: { top_hits: {} }) do |aggregation|
        aggregation.custom(custom_key: "custom_value")
      end

      expect(query.request[:aggregations][:top_hits][:top_hits][:custom_key]).to eq("custom_value")
    end
  end

  describe "#highlight" do
    it "adds a custom entry to the request" do
      ProductIndex.import create(:product, title: "Title highlight")

      query = ProductIndex.search("title:highlight").aggregate(top_hits: { top_hits: {} }) do |aggregation|
        aggregation.highlight([:title])
      end

      expect(query.aggregations("top_hits").hits.hits.first.highlight.title).to be_present
    end
  end

  describe "#page" do
    it "returns the respective result window" do
      product1, product2 = create_list(:product, 2)

      ProductIndex.import [product1, product2]

      query = ProductIndex.aggregate(top_hits: { top_hits: {} }) do |aggregation|
        aggregation.sort(:id).per(1).page(2)
      end

      expect(query.aggregations("top_hits").hits.hits.first._id).to eq(product2.id.to_s)
    end
  end

  describe "#per" do
    it "returns the respective result window" do
      ProductIndex.import create_list(:product, 2)

      query = ProductIndex.aggregate(top_hits: { top_hits: {} }) do |aggregation|
        aggregation.per(1)
      end

      expect(query.aggregations("top_hits").hits.hits.size).to eq(1)
    end
  end

  describe "#paginate" do
    it "returns the respective result window" do
      product1, product2 = create_list(:product, 2)

      ProductIndex.import [product1, product2]

      query = ProductIndex.aggregate(top_hits: { top_hits: {} }) do |aggregation|
        aggregation.sort(:id).paginate(page: 2, per_page: 1)
      end

      expect(query.aggregations("top_hits").hits.hits.first._id).to eq(product2.id.to_s)
    end
  end

  describe "#limit" do
    it "returns the respective result window" do
      ProductIndex.import create_list(:product, 2)

      query = ProductIndex.aggregate(top_hits: { top_hits: {} }) do |aggregation|
        aggregation.limit(1)
      end

      expect(query.aggregations("top_hits").hits.hits.size).to eq(1)
    end
  end

  describe "#offset" do
    it "returns the respective result window" do
      product1, product2 = create_list(:product, 2)

      ProductIndex.import [product1, product2]

      query = ProductIndex.aggregate(top_hits: { top_hits: {} }) do |aggregation|
        aggregation.sort(:id).limit(1).offset(1)
      end

      expect(query.aggregations("top_hits").hits.hits.first._id).to eq(product2.id.to_s)
    end
  end

  describe "#sort" do
    it "returns the results in the specified order" do
      product1, product2 = create_list(:product, 2)

      ProductIndex.import [product1, product2]

      query = ProductIndex.aggregate(top_hits: { top_hits: {} }) do |aggregation|
        aggregation.sort(id: "desc")
      end

      expect(query.aggregations("top_hits").hits.hits.map(&:_id)).to eq([product2, product1].map(&:id).map(&:to_s))
    end
  end

  describe "#resort" do
    it "overrides the previous sorting and returns the results in the specified order" do
      product1, product2 = create_list(:product, 2)

      ProductIndex.import [product1, product2]

      query = ProductIndex.aggregate(top_hits: { top_hits: {} }) do |aggregation|
        aggregation.sort(id: "desc").resort(:id)
      end

      expect(query.aggregations("top_hits").hits.hits.map(&:_id)).to eq([product1, product2].map(&:id).map(&:to_s))
    end
  end

  describe "#source" do
    it "returns the specified fields only" do
      ProductIndex.import create(:product)

      query = ProductIndex.aggregate(top_hits: { top_hits: {} }) do |aggregation|
        aggregation.source([:id, :title])
      end

      expect(query.aggregations("top_hits").hits.hits.first._source.keys).to eq(["id", "title"])
    end
  end
end
