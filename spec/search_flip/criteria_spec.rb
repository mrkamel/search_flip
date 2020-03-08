require File.expand_path("../spec_helper", __dir__)

RSpec.describe SearchFlip::Criteria do
  describe "delegation" do
    subject { SearchFlip::Criteria.new(target: ProductIndex) }

    methods = [
      :total_entries, :current_page, :previous_page, :prev_page, :next_page,
      :first_page?, :last_page?, :out_of_range?, :total_pages, :hits, :ids,
      :count, :size, :length, :took, :aggregations, :suggestions, :scope,
      :results, :records, :scroll_id, :raw_response
    ]

    methods.each do |method|
      it { should delegate(method).to(:response) }
    end

    it { should delegate(:connection).to(:target) }
  end

  describe "#to_query" do
    it "returns the added queries and filters, including post filters in query mode" do
      query =
        ProductIndex
          .where_not(category: "category3")
          .must(terms: { category: ["category1", "category2"] })
          .post_where(id: [1, 2], sale: true)

      expect(query.to_query).to eq(
        bool: {
          must: [
            { terms: { category: ["category1", "category2"] } },
            { terms: { id: [1, 2] } },
            { term: { sale: true } }
          ],
          must_not: [
            { term: { category: "category3" } }
          ]
        }
      )
    end
  end

  describe "#to_filter" do
    it "returns the added queries and filters, including post filters in filter mode" do
      query =
        ProductIndex
          .where_not(category: "category3")
          .must(terms: { category: ["category1", "category2"] })
          .post_where(id: [1, 2], sale: true)

      expect(query.to_filter).to eq(
        bool: {
          filter: [
            { terms: { category: ["category1", "category2"] } },
            { terms: { id: [1, 2] } },
            { term: { sale: true } }
          ],
          must_not: [
            { term: { category: "category3" } }
          ]
        }
      )
    end
  end

  describe "#merge" do
    it "merges criterias" do
      product1 = create(:product, price: 100, category: "category1")
      product2 = create(:product, price: 200, category: "category2")
      product3 = create(:product, price: 300, category: "category1")

      ProductIndex.import [product1, product2, product3]

      query = ProductIndex.where(price: 50..250).aggregate(:category).merge(ProductIndex.where(category: "category1"))

      expect(query.records).to eq([product1])
    end

    describe "assignments" do
      methods = [
        :profile_value, :failsafe_value, :terminate_after_value, :timeout_value,
        :offset_value, :limit_value, :scroll_args, :source_value, :preference_value,
        :search_type_value, :routing_value, :track_total_hits_value, :explain_value
      ]

      methods.each do |method|
        it "replaces the values" do
          criteria1 = SearchFlip::Criteria.new(target: TestIndex)
          criteria1.send("#{method}=", "value1")

          criteria2 = SearchFlip::Criteria.new(target: TestIndex)
          criteria2.send("#{method}=", "value2")

          expect(criteria1.merge(criteria2).send(method)).to eq("value2")
        end
      end
    end

    describe "array concatenations" do
      methods = [
        :sort_values, :includes_values, :preload_values, :eager_load_values,
        :must_values, :must_not_values, :filter_values,
        :post_must_values, :post_must_not_values, :post_filter_values
      ]

      methods.each do |method|
        it "concatenates the values for #{method}" do
          criteria1 = SearchFlip::Criteria.new(target: TestIndex)
          criteria1.send("#{method}=", ["value1"])

          criteria2 = SearchFlip::Criteria.new(target: TestIndex)
          criteria2.send("#{method}=", ["value2"])

          result = criteria1.merge(criteria2)

          expect(result.send(method)).to eq(["value1", "value2"])
        end
      end
    end

    describe "hash merges" do
      methods = [
        :highlight_values, :suggest_values, :custom_value, :aggregation_values
      ]

      methods.each do |method|
        it "merges the values for #{method}" do
          criteria1 = SearchFlip::Criteria.new(target: TestIndex)
          criteria1.send("#{method}=", key1: "value1")

          criteria2 = SearchFlip::Criteria.new(target: TestIndex)
          criteria2.send("#{method}=", key2: "value2")

          result = criteria1.merge(criteria2)

          expect(result.send(method)).to eq(key1: "value1", key2: "value2")
        end
      end
    end
  end

  describe "#criteria" do
    it "returns self" do
      criteria = ProductIndex.criteria

      expect(criteria.criteria.object_id).to eq(criteria.object_id)
    end
  end

  describe "#timeout" do
    it "sets the query timeout" do
      query = ProductIndex.timeout("1s")

      expect(query.request[:timeout]).to eq("1s")
      expect { query.execute }.not_to raise_error
    end
  end

  describe "#terminate_after" do
    it "sets the terminate after value" do
      query = ProductIndex.terminate_after(1)

      expect(query.request[:terminate_after]).to eq(1)
      expect { query.execute }.not_to raise_error
    end
  end

  describe "#where" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, price: 100, category: "category1")
      product2 = create(:product, price: 200, category: "category2")
      product3 = create(:product, price: 300, category: "category1")

      ProductIndex.import [product1, product2, product3]

      query1 = ProductIndex.where(price: 100..200)
      query2 = query1.where(category: "category1")

      expect(query1.records.to_set).to eq([product1, product2].to_set)
      expect(query2.records).to eq([product1])
    end

    it "works with arrays" do
      expected1 = create(:product, title: "expected1")
      expected2 = create(:product, title: "expected2")
      rejected = create(:product, title: "rejected")

      ProductIndex.import [expected1, expected2, rejected]

      query = ProductIndex.where(title: ["expected1", "expected2"])

      expect(query.records.to_set).to eq([expected1, expected2].to_set)
    end

    it "works with ranges" do
      expected1 = create(:product, price: 100)
      expected2 = create(:product, price: 200)
      rejected = create(:product, price: 300)

      ProductIndex.import [expected1, expected2, rejected]

      query = ProductIndex.where(price: 100..200)

      expect(query.records.to_set).to eq([expected1, expected2].to_set)
    end

    it "works with nils" do
      expected = create(:product, price: nil)
      rejected = create(:product, price: 100)

      ProductIndex.import [expected, rejected]

      query = ProductIndex.where(price: nil)

      expect(query.records).to eq([expected])
    end
  end

  describe "#where_not" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, price: 100, category: "category1")
      product2 = create(:product, price: 200, category: "category2")
      product3 = create(:product, price: 300, category: "category1")

      ProductIndex.import [product1, product2, product3]

      query1 = ProductIndex.where_not(price: 250..350)
      query2 = query1.where_not(category: "category2")

      expect(query1.records.to_set).to eq([product1, product2].to_set)
      expect(query2.records).to eq([product1])
    end

    it "works with arrays" do
      expected = create(:product, title: "expected")
      rejected1 = create(:product, title: "rejected1")
      rejected2 = create(:product, title: "rejected2")

      ProductIndex.import [expected, rejected1, rejected2]

      query = ProductIndex.where_not(title: ["rejected1", "rejected2"])

      expect(query.records).to eq([expected])
    end

    it "works with ranges" do
      expected = create(:product, price: 100)
      rejected1 = create(:product, price: 200)
      rejected2 = create(:product, price: 300)

      ProductIndex.import [expected, rejected1, rejected2]

      query = ProductIndex.where_not(price: 200..300)

      expect(query.records).to eq([expected])
    end

    it "works with nils" do
      expected = create(:product, price: 100)
      rejected = create(:product, price: nil)

      ProductIndex.import [expected, rejected]

      query = ProductIndex.where_not(price: nil)

      expect(query.records).to eq([expected])
    end
  end

  describe "#with_settings" do
    it "sets the target to the new anonymous class" do
      query = ProductIndex.where(id: 1).with_settings(index_name: "new_user_index")

      expect(query.target.name).to be_nil
      expect(query.target.index_name).to eq("new_user_index")
    end

    it "keeps the constraints" do
      expected = create(:product)
      rejected = create(:product)

      ProductIndex.import [expected, rejected]

      query = ProductIndex.where(id: expected.id).with_settings(index_name: ProductIndex.index_name)

      expect(query.records).to eq([expected])
    end
  end

  describe "#filter" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, price: 100, category: "category1")
      product2 = create(:product, price: 200, category: "category2")
      product3 = create(:product, price: 300, category: "category1")

      ProductIndex.import [product1, product2, product3]

      query1 = ProductIndex.filter(range: { price: { gte: 100, lte: 200 } })
      query2 = query1.filter(term: { category: "category1" })

      expect(query1.records.to_set).to eq([product1, product2].to_set)
      expect(query2.records).to eq([product1])
    end
  end

  describe "#must" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, price: 100, category: "category1")
      product2 = create(:product, price: 200, category: "category2")
      product3 = create(:product, price: 300, category: "category1")

      ProductIndex.import [product1, product2, product3]

      query1 = ProductIndex.must(range: { price: { gte: 100, lte: 200 } })
      query2 = query1.must(term: { category: "category1" })

      expect(query1.records.to_set).to eq([product1, product2].to_set)
      expect(query2.records).to eq([product1])
    end
  end

  describe "#must_not" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, price: 100, category: "category1")
      product2 = create(:product, price: 200, category: "category2")
      product3 = create(:product, price: 300, category: "category1")

      ProductIndex.import [product1, product2, product3]

      query1 = ProductIndex.must_not(range: { price: { gt: 200, lte: 300 } })
      query2 = query1.must_not(term: { category: "category2" })

      expect(query1.records.to_set).to eq([product1, product2].to_set)
      expect(query2.records).to eq([product1])
    end
  end

  describe "#should" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, price: 100, category: "category1")
      product2 = create(:product, price: 200, category: "category2")
      product3 = create(:product, price: 300, category: "category1")

      ProductIndex.import [product1, product2, product3]

      query = ProductIndex.should([
        { range: { price: { gte: 100, lt: 200 } } },
        { term: { category: "category2" } }
      ])

      expect(query.records.to_set).to eq([product1, product2].to_set)
    end

    it "allows to set bool options" do
      product1 = create(:product, category: "category1")
      product2 = create(:product, category: "category2")

      ProductIndex.import [product1, product2]

      query = ProductIndex.should(
        [
          { constant_score: { filter: { term: { category: "category1" } }, boost: 0 } },
          { constant_score: { filter: { term: { category: "category2" } }, boost: 1 } }
        ],
        boost: 2
      )

      expect(query.records).to eq([product2, product1])
      expect(query.results.map(&:_hit).map(&:_score)).to eq([2, 0])
    end
  end

  describe "#range" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, price: 100)
      product2 = create(:product, price: 200)
      product3 = create(:product, price: 300)

      ProductIndex.import [product1, product2, product3]

      query1 = ProductIndex.range(:price, gte: 100, lte: 200)
      query2 = query1.range(:price, gte: 200, lte: 300)

      expect(query1.records.to_set).to eq([product1, product2].to_set)
      expect(query2.records).to eq([product2])
    end
  end

  describe "#match_all" do
    it "matches all documents" do
      expected1 = create(:product)
      expected2 = create(:product)

      ProductIndex.import [expected1, expected2]

      query = ProductIndex.match_all

      expect(query.records.to_set).to eq([expected1, expected2].to_set)
    end
  end

  describe "#exists" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, title: "title1", description: "description1")
      product2 = create(:product, title: "title2", description: nil)
      product3 = create(:product, title: nil, description: "description2")

      ProductIndex.import [product1, product2, product3]

      query1 = ProductIndex.exists(:title)
      query2 = query1.exists(:description)

      expect(query1.records.to_set).to eq([product1, product2].to_set)
      expect(query2.records).to eq([product1])
    end
  end

  describe "#exists_not" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, title: nil, description: nil)
      product2 = create(:product, title: nil, description: "description2")
      product3 = create(:product, title: "title3", description: "description3")

      ProductIndex.import [product1, product2, product3]

      query1 = ProductIndex.exists_not(:title)
      query2 = query1.exists_not(:description)

      expect(query1.records.to_set).to eq([product1, product2].to_set)
      expect(query2.records).to eq([product1])
    end
  end

  describe "#post_search" do
    it "sets up the constraints correctly and is chainable" do
      if ProductIndex.connection.version.to_i >= 2
        product1 = create(:product, title: "title1", category: "category1")
        product2 = create(:product, title: "title2", category: "category2")
        product3 = create(:product, title: "title3", category: "category1")

        ProductIndex.import [product1, product2, product3]

        query1 = ProductIndex.aggregate(:category).post_search("title1 OR title2")
        query2 = query1.post_search("category1")

        expect(query1.records.to_set).to eq([product1, product2].to_set)
        expect(query2.records).to eq([product1])

        aggregations1 = query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
        expect(aggregations1).to eq("category1" => 2, "category2" => 1)

        aggregations2 = query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
        expect(aggregations2).to eq("category1" => 2, "category2" => 1)
      end
    end
  end

  describe "#post_where" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, price: 100, category: "category1")
      product2 = create(:product, price: 200, category: "category2")
      product3 = create(:product, price: 300, category: "category1")

      ProductIndex.import [product1, product2, product3]

      query1 = ProductIndex.aggregate(:category).post_where(price: 100..200)
      query2 = query1.post_where(category: "category1")

      expect(query1.records.to_set).to eq([product1, product2].to_set)
      expect(query2.records).to eq([product1])

      aggregations1 = query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations1).to eq("category1" => 2, "category2" => 1)

      aggregations2 = query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations2).to eq("category1" => 2, "category2" => 1)
    end

    it "works with arrays" do
      expected1 = create(:product, title: "expected1", category: "category1")
      expected2 = create(:product, title: "expected2", category: "category2")
      rejected = create(:product, title: "rejected", category: "category1")

      ProductIndex.import [expected1, expected2, rejected]

      query = ProductIndex.aggregate(:category).post_where(title: ["expected1", "expected2"])

      expect(query.records.to_set).to eq([expected1, expected2].to_set)

      aggregations = query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end

    it "works with ranges" do
      expected1 = create(:product, price: 100, category: "category1")
      expected2 = create(:product, price: 200, category: "category2")
      rejected = create(:product, price: 300, category: "category1")

      ProductIndex.import [expected1, expected2, rejected]

      query = ProductIndex.aggregate(:category).post_where(price: 100..200)

      expect(query.records.to_set).to eq([expected1, expected2].to_set)

      aggregations = query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end

    it "works with nil" do
      expected1 = create(:product, price: nil, category: "category1")
      expected2 = create(:product, price: nil, category: "category2")
      rejected = create(:product, price: 300, category: "category1")

      ProductIndex.import [expected1, expected2, rejected]

      query = ProductIndex.aggregate(:category).post_where(price: nil)

      expect(query.records.to_set).to eq([expected1, expected2].to_set)

      aggregations = query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end
  end

  describe "#post_where_not" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, price: 100, category: "category1")
      product2 = create(:product, price: 200, category: "category2")
      product3 = create(:product, price: 300, category: "category1")

      ProductIndex.import [product1, product2, product3]

      query1 = ProductIndex.aggregate(:category).post_where_not(price: 250..350)
      query2 = query1.post_where_not(category: "category2")

      expect(query1.records.to_set).to eq([product1, product2].to_set)
      expect(query2.records).to eq([product1])

      aggregations = query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)

      aggregations = query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end

    it "works with arrays" do
      expected = create(:product, title: "expected", category: "category1")
      rejected1 = create(:product, title: "rejected1", category: "category2")
      rejected2 = create(:product, title: "rejected2", category: "category1")

      ProductIndex.import [expected, rejected1, rejected2]

      query = ProductIndex.aggregate(:category).post_where_not(title: ["rejected1", "rejected2"])

      expect(query.records).to eq([expected])

      aggregations = query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end

    it "works with ranges" do
      expected = create(:product, price: 100, category: "category1")
      rejected1 = create(:product, price: 200, category: "category2")
      rejected2 = create(:product, price: 300, category: "category1")

      ProductIndex.import [expected, rejected1, rejected2]

      query = ProductIndex.aggregate(:category).post_where_not(price: 200..300)

      expect(query.records).to eq([expected])

      aggregations = query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end

    it "works with nils" do
      expected = create(:product, price: 100, category: "category1")
      rejected1 = create(:product, price: nil, category: "category2")
      rejected2 = create(:product, price: nil, category: "category1")

      ProductIndex.import [expected, rejected1, rejected2]

      query = ProductIndex.aggregate(:category).post_where_not(price: nil)

      expect(query.records).to eq([expected])

      aggregations = query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end
  end

  describe "#post_filter" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, price: 100, category: "category1")
      product2 = create(:product, price: 200, category: "category2")
      product3 = create(:product, price: 300, category: "category1")

      ProductIndex.import [product1, product2, product3]

      query1 = ProductIndex.aggregate(:category).post_filter(range: { price: { gte: 100, lte: 200 } })
      query2 = query1.post_filter(term: { category: "category1" })

      expect(query1.records.to_set).to eq([product1, product2].to_set)
      expect(query2.records).to eq([product1])

      aggregations = query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)

      aggregations = query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end
  end

  describe "#post_must" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, price: 100, category: "category1")
      product2 = create(:product, price: 200, category: "category2")
      product3 = create(:product, price: 300, category: "category1")

      ProductIndex.import [product1, product2, product3]

      query1 = ProductIndex.aggregate(:category).post_must(range: { price: { gte: 100, lte: 200 } })
      query2 = query1.post_must(term: { category: "category1" })

      expect(query1.records.to_set).to eq([product1, product2].to_set)
      expect(query2.records).to eq([product1])

      aggregations = query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)

      aggregations = query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end
  end

  describe "#post_must_not" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, price: 100, category: "category1")
      product2 = create(:product, price: 200, category: "category2")
      product3 = create(:product, price: 300, category: "category1")

      ProductIndex.import [product1, product2, product3]

      query1 = ProductIndex.aggregate(:category).post_must_not(range: { price: { gte: 50, lte: 150 } })
      query2 = query1.post_must_not(term: { category: "category1" })

      expect(query1.records.to_set).to eq([product2, product3].to_set)
      expect(query2.records).to eq([product2])

      aggregations = query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)

      aggregations = query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end
  end

  describe "#post_should" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, price: 100, category: "category1")
      product2 = create(:product, price: 200, category: "category3")
      product3 = create(:product, price: 300, category: "category2")
      product4 = create(:product, price: 400, category: "category1")

      ProductIndex.import [product1, product2, product3, product4]

      query1 = ProductIndex.aggregate(:category).post_should([
        { term: { category: "category1" } },
        { term: { category: "category2" } }
      ])

      query2 = query1.post_should([
        { range: { price: { gte: 50, lte: 150 } } },
        { range: { price: { gte: 250, lte: 350 } } }
      ])

      expect(query1.records.to_set).to eq([product1, product3, product4].to_set)
      expect(query2.records.to_set).to eq([product1, product3].to_set)

      aggregations = query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1, "category3" => 1)

      aggregations = query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1, "category3" => 1)
    end
  end

  describe "#post_range" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, price: 100, category: "category1")
      product2 = create(:product, price: 200, category: "category2")
      product3 = create(:product, price: 300, category: "category1")

      ProductIndex.import [product1, product2, product3]

      query1 = ProductIndex.aggregate(:category).post_range(:price, gte: 100, lte: 200)
      query2 = query1.post_range(:price, gte: 200, lte: 300)

      expect(query1.records.to_set).to eq([product1, product2].to_set)
      expect(query2.records).to eq([product2])

      aggregations = query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)

      aggregations = query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end
  end

  describe "#post_exists" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, title: "title1", description: "description1", category: "category1")
      product2 = create(:product, title: "title2", description: nil, category: "category2")
      product3 = create(:product, title: nil, description: "description2", category: "category1")

      ProductIndex.import [product1, product2, product3]

      query1 = ProductIndex.aggregate(:category).post_exists(:title)
      query2 = query1.post_exists(:description)

      expect(query1.records.to_set).to eq([product1, product2].to_set)
      expect(query2.records).to eq([product1])

      aggregations = query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)

      aggregations = query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end
  end

  describe "#post_exists" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, title: "title1", description: "description1", category: "category1")
      product2 = create(:product, title: "title2", description: nil, category: "category2")
      product3 = create(:product, title: nil, description: "description2", category: "category1")

      ProductIndex.import [product1, product2, product3]

      query1 = ProductIndex.aggregate(:category).post_exists(:title)
      query2 = query1.post_exists(:description)

      expect(query1.records.to_set).to eq([product1, product2].to_set)
      expect(query2.records).to eq([product1])

      aggregations = query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)

      aggregations = query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end
  end

  describe "#post_exists" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, title: "title1", description: "description1", category: "category1")
      product2 = create(:product, title: "title2", description: nil, category: "category2")
      product3 = create(:product, title: nil, description: "description2", category: "category1")

      ProductIndex.import [product1, product2, product3]

      query1 = ProductIndex.aggregate(:category).post_exists(:title)
      query2 = query1.post_exists(:description)

      expect(query1.records.to_set).to eq([product1, product2].to_set)
      expect(query2.records).to eq([product1])

      aggregations = query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)

      aggregations = query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end
  end

  describe "#post_exists_not" do
    it "sets up the constraints correctly and is chainable" do
      product1 = create(:product, title: nil, description: nil, category: "category1")
      product2 = create(:product, title: nil, description: "description2", category: "category2")
      product3 = create(:product, title: "title3", description: "description3", category: "category1")

      ProductIndex.import [product1, product2, product3]

      query1 = ProductIndex.aggregate(:category).post_exists_not(:title)
      query2 = query1.post_exists_not(:description)

      expect(query1.records.to_set).to eq([product1, product2].to_set)
      expect(query2.records).to eq([product1])

      aggregations = query1.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)

      aggregations = query2.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      expect(aggregations).to eq("category1" => 2, "category2" => 1)
    end
  end

  describe "#aggregate" do
    it "sets up the constraints correctly and is chainable" do
      ProductIndex.import create_list(:product, 3, category: "category1", price: 10)
      ProductIndex.import create_list(:product, 2, category: "category2", price: 20)
      ProductIndex.import create_list(:product, 1, category: "category3", price: 30)

      query = ProductIndex.aggregate(:category, size: 2).aggregate(price_sum: { sum: { field: "price" } })

      category_aggregations = query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      price_aggregation = query.aggregations(:price_sum).value

      expect(category_aggregations).to eq("category1" => 3, "category2" => 2)
      expect(price_aggregation).to eq(100)
    end

    it "works with hashes" do
      ProductIndex.import create_list(:product, 3, category: "category1")
      ProductIndex.import create_list(:product, 2, category: "category2")
      ProductIndex.import create_list(:product, 1, category: "category3")

      query = ProductIndex.aggregate(category: { terms: { field: :category } })
      aggregations = query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }

      expect(aggregations).to eq("category1" => 3, "category2" => 2, "category3" => 1)
    end

    it "allows sub-aggregations" do
      ProductIndex.import create_list(:product, 3, category: "category1", price: 15)
      ProductIndex.import create_list(:product, 2, category: "category2", price: 20)
      ProductIndex.import create_list(:product, 1, category: "category3", price: 25)

      query = ProductIndex.aggregate(:category) do |aggregation|
        aggregation.aggregate(price_sum: { sum: { field: "price" } })
      end

      category_aggregations = query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.doc_count }
      price_sum_aggregations = query.aggregations(:category).each_with_object({}) { |(key, agg), hash| hash[key] = agg.price_sum.value }

      expect(category_aggregations).to eq("category1" => 3, "category2" => 2, "category3" => 1)
      expect(price_sum_aggregations).to eq("category1" => 45, "category2" => 40, "category3" => 25)
    end
  end

  describe "#profile" do
    it "sets up the constraints correctly" do
      if ProductIndex.connection.version.to_i >= 2
        expect(ProductIndex.profile(true).raw_response["profile"]).not_to be_nil
      end
    end
  end

  describe "#scroll" do
    it "scrolls over the full result set" do
      products = create_list(:product, 15)

      ProductIndex.import products

      criteria = ProductIndex.limit(10).scroll(timeout: "1m")

      result = []
      iterations = 0

      until criteria.records.empty?
        result += criteria.records
        iterations += 1

        criteria = criteria.scroll(id: criteria.scroll_id, timeout: "1m")
      end

      expect(products.to_set).to eq(result.to_set)
      expect(iterations).to eq(2)
    end
  end

  describe "#delete" do
    it "delets the matching documents" do
      product1, product2, product3 = create_list(:product, 3)

      ProductIndex.import [product1, product2, product3]

      expect { ProductIndex.where(id: [product1.id, product2.id]).delete }.to change { ProductIndex.total_count }.by(-2)
    end

    it "accepts additional params" do
      product = create(:product)

      ProductIndex.import(product)

      expect { ProductIndex.where(id: product.id).delete(conflicts: "proceed") }.to change { ProductIndex.total_count }.by(-1)
    end
  end

  describe "#source" do
    it "constraints the returned source fields" do
      product = create(:product, title: "Title", price: 10)

      ProductIndex.import product

      results = ProductIndex.where(id: product.id).results

      expect(results.first.id).not_to be_nil
      expect(results.first.title).not_to be_nil
      expect(results.first.price).not_to be_nil

      results = ProductIndex.where(id: product.id).source([:id, :price]).results

      expect(results.first.id).not_to be_nil
      expect(results.first.title).to be_nil
      expect(results.first.price).not_to be_nil
    end
  end

  describe "#includes" do
    it "does not raise any errors" do
      user = create(:user)
      comments = create_list(:comment, 2)
      product = create(:product, user: user, comments: comments)

      ProductIndex.import product

      record = ProductIndex.includes(:user).includes(:comments).records.first

      expect(record).not_to be_nil
      expect(record.user).to eq(user)
      expect(record.comments.to_set).to eq(comments.to_set)
    end
  end

  describe "#eager_load" do
    it "does not raise any errors" do
      user = create(:user)
      comments = create_list(:comment, 2)
      product = create(:product, user: user, comments: comments)

      ProductIndex.import product

      record = ProductIndex.eager_load(:user).eager_load(:comments).records.first

      expect(record).not_to be_nil
      expect(record.user).to eq(user)
      expect(record.comments.to_set).to eq(comments.to_set)
    end
  end

  describe "#preload" do
    it "does not raise any errors" do
      user = create(:user)
      comments = create_list(:comment, 2)
      product = create(:product, user: user, comments: comments)

      ProductIndex.import product

      record = ProductIndex.preload(:user).preload(:comments).records.first

      expect(record).not_to be_nil
      expect(record.user).to eq(user)
      expect(record.comments.to_set).to eq(comments.to_set)
    end
  end

  describe "#sort" do
    it "sorts correctly and is chainable" do
      product1 = create(:product, rank: 2, price: 100)
      product2 = create(:product, rank: 2, price: 90)
      product3 = create(:product, rank: 1, price: 120)
      product4 = create(:product, rank: 0, price: 110)

      ProductIndex.import [product1, product2, product3, product4]

      expect(ProductIndex.sort({ rank: :desc }, price: :asc).records).to eq([product2, product1, product3, product4])
      expect(ProductIndex.sort(rank: :desc).sort(:price).records).to eq([product2, product1, product3, product4])
      expect(ProductIndex.sort(:price).sort(rank: :desc).records).to eq([product2, product1, product4, product3])
    end
  end

  describe "#resort" do
    it "overwrites existing sort criterias" do
      product1 = create(:product, rank: 2, price: 100)
      product2 = create(:product, rank: 2, price: 90)
      product3 = create(:product, rank: 1, price: 120)
      product4 = create(:product, rank: 0, price: 110)

      ProductIndex.import [product1, product2, product3, product4]

      expect(ProductIndex.sort(:price).resort({ rank: :desc }, price: :asc).records).to eq([product2, product1, product3, product4])
      expect(ProductIndex.sort(rank: :desc).resort(:price).records).to eq([product2, product1, product4, product3])
    end
  end

  describe "#offset" do
    it "sets the query document offset" do
      product1 = create(:product, rank: 1)
      product2 = create(:product, rank: 2)
      product3 = create(:product, rank: 3)

      ProductIndex.import [product1, product2, product3]

      query = ProductIndex.sort(:rank).offset(1)

      expect(query.records).to eq([product2, product3])
      expect(query.offset(2).records).to eq([product3])
    end
  end

  describe "#limit" do
    it "sets the query document limit" do
      product1 = create(:product, rank: 1)
      product2 = create(:product, rank: 2)
      product3 = create(:product, rank: 3)

      ProductIndex.import [product1, product2, product3]

      query = ProductIndex.sort(:rank).limit(1)

      expect(query.records).to eq([product1])
      expect(query.limit(2).records).to eq([product1, product2])
    end
  end

  describe "#paginate" do
    it "sets the query document offset and limit" do
      product1 = create(:product, rank: 1)
      product2 = create(:product, rank: 2)
      product3 = create(:product, rank: 3)

      ProductIndex.import [product1, product2, product3]

      query = ProductIndex.sort(:rank).paginate(page: 1, per_page: 2)

      expect(query.records).to eq([product1, product2])
      expect(query.paginate(page: 2, per_page: 2).records).to eq([product3])
    end
  end

  describe "#page" do
    it "sets the query document offset" do
      expect(ProductIndex.page(1).offset_value).to eq(0)
      expect(ProductIndex.page(2).offset_value).to eq(30)
      expect(ProductIndex.page(3).per(50).offset_value).to eq(100)
    end
  end

  describe "#limit" do
    it "sets the query document limit" do
      expect(ProductIndex.per(50).limit_value).to eq(50)
    end
  end

  describe "#search" do
    it "sets up the constraints correctly" do
      product1 = create(:product, title: "Title1", description: "Description1", price: 10)
      product2 = create(:product, title: "Title2", description: "Description2", price: 20)
      product3 = create(:product, title: "Title3", description: "Description2", price: 30)

      ProductIndex.import [product1, product2, product3]

      expect(ProductIndex.search("Title1 OR Title3").records.to_set).to eq([product1, product3].to_set)
      expect(ProductIndex.search("Title1 Title3", default_operator: :OR).records.to_set).to eq([product1, product3].to_set)
      expect(ProductIndex.search("Title1 OR Title2").search("Title1 OR Title3").records).to eq([product1])
      expect(ProductIndex.search("Title1 OR Title3").where(price: 5..15).records).to eq([product1])
    end
  end

  describe "#highlight" do
    it "adds highlighting to the query and is chainable" do
      product1 = create(:product, title: "Title1 highlight", description: "Description1 highlight")
      product2 = create(:product, title: "Title2 highlight", description: "Description2 highlight")

      ProductIndex.import [product1, product2]

      results = ProductIndex.sort(:id).highlight([:title, :description]).search("title:highlight description:highlight").results

      expect(results[0]._hit.highlight.title).to eq(["Title1 <em>highlight</em>"])
      expect(results[0]._hit.highlight.description).to eq(["Description1 <em>highlight</em>"])

      expect(results[1]._hit.highlight.title).to eq(["Title2 <em>highlight</em>"])
      expect(results[1]._hit.highlight.description).to eq(["Description2 <em>highlight</em>"])

      results = ProductIndex.sort(:id).highlight([:title, :description], require_field_match: false).search("highlight").results

      expect(results[0]._hit.highlight.title).to eq(["Title1 <em>highlight</em>"])
      expect(results[0]._hit.highlight.description).to eq(["Description1 <em>highlight</em>"])

      expect(results[1]._hit.highlight.title).to eq(["Title2 <em>highlight</em>"])
      expect(results[1]._hit.highlight.description).to eq(["Description2 <em>highlight</em>"])

      query = ProductIndex.sort(:id).search("title:highlight")
      query = query.highlight(:title, require_field_match: true).highlight(:description, require_field_match: true)

      results = query.results

      expect(results[0]._hit.highlight.title).to eq(["Title1 <em>highlight</em>"])
      expect(results[0]._hit.highlight.description).to be_nil

      expect(results[1]._hit.highlight.title).to eq(["Title2 <em>highlight</em>"])
      expect(results[1]._hit.highlight.description).to be_nil
    end
  end

  describe "#suggest" do
    it "adds suggest to the query" do
      product = create(:product, title: "Title", description: "Description")

      ProductIndex.import product

      suggestions = ProductIndex.suggest(:suggestion, text: "Desciption", term: { field: "description" }).suggestions(:suggestion)

      expect(suggestions.first["text"]).to eq("description")
    end
  end

  describe "#find_in_batches" do
    it "iterates the records in batches of the specified size" do
      expected1 = create(:product, title: "expected", rank: 1)
      expected2 = create(:product, title: "expected", rank: 2)
      expected3 = create(:product, title: "expected", rank: 3)
      rejected = create(:product, title: "rejected")

      create :product, title: "rejected"

      ProductIndex.import [expected1, expected2, expected3, rejected]

      actual = ProductIndex.where(title: "expected").sort(:rank).find_in_batches(batch_size: 2).to_a

      expect(actual).to eq([[expected1, expected2], [expected3]])
    end
  end

  describe "#find_results_in_batches" do
    it "iterates the results in batches of the specified size" do
      expected1 = create(:product, title: "expected", rank: 1)
      expected2 = create(:product, title: "expected", rank: 2)
      expected3 = create(:product, title: "expected", rank: 3)
      rejected = create(:product, title: "rejected")

      create :product, title: "rejected"

      ProductIndex.import [expected1, expected2, expected3, rejected]

      actual = ProductIndex.where(title: "expected").sort(:rank).find_results_in_batches(batch_size: 2).map { |batch| batch.map(&:id) }

      expect(actual).to eq([[expected1.id, expected2.id], [expected3.id]])
    end
  end

  describe "#find_each" do
    it "iterates the records" do
      expected1 = create(:product, title: "expected", rank: 1)
      expected2 = create(:product, title: "expected", rank: 2)
      expected3 = create(:product, title: "expected", rank: 3)
      rejected = create(:product, title: "rejected")

      create :product, title: "rejected"

      ProductIndex.import [expected1, expected2, expected3, rejected]

      actual = ProductIndex.where(title: "expected").sort(:rank).find_each(batch_size: 2).to_a

      expect(actual).to eq([expected1, expected2, expected3])
    end
  end

  describe "#find_each_result" do
    it "iterates the results" do
      expected1 = create(:product, title: "expected", rank: 1)
      expected2 = create(:product, title: "expected", rank: 2)
      expected3 = create(:product, title: "expected", rank: 3)
      rejected = create(:product, title: "rejected")

      create :product, title: "rejected"

      ProductIndex.import [expected1, expected2, expected3, rejected]

      actual = ProductIndex.where(title: "expected").sort(:rank).find_each_result(batch_size: 2).map(&:id)

      expect(actual).to eq([expected1.id, expected2.id, expected3.id])
    end
  end

  describe "#failsafe" do
    it "prevents query syntax exceptions" do
      expect { ProductIndex.search("syntax/error").records }.to raise_error(SearchFlip::ResponseError)

      query = ProductIndex.failsafe(true).search("syntax/error")

      expect(query.records).to eq([])
      expect(query.total_entries).to eq(0)
    end
  end

  describe "#fresh" do
    it "returns a new criteria without a cached response" do
      create :product

      query = ProductIndex.criteria.tap(&:records)

      expect(query.instance_variable_get(:@response)).not_to be_nil

      expect(query.object_id).not_to eq(query.fresh.object_id)
      expect(query.fresh.instance_variable_get(:@response)).to be_nil
    end
  end

  describe "#respond_to?" do
    it "checks whether or not the index class responds to the method" do
      temp_index = Class.new(ProductIndex)

      expect(temp_index.criteria.respond_to?(:test_scope)).to eq(false)

      temp_index.scope(:test_scope) { match_all }

      expect(temp_index.criteria.respond_to?(:test_scope)).to eq(true)
    end
  end

  describe "#method_missing" do
    it "delegates to the index class" do
      temp_index = Class.new(ProductIndex)

      expected = create(:product, title: "expected")
      rejected = create(:product, title: "rejected")

      temp_index.import [expected, rejected]

      temp_index.scope(:with_title) { |title| where(title: title) }

      records = temp_index.criteria.with_title("expected").records

      expect(records).to eq([expected])
    end
  end

  describe "#track_total_hits" do
    it "is added to the request" do
      if ProductIndex.connection.version.to_i >= 7
        query = ProductIndex.track_total_hits(false)
        expect(query.request[:track_total_hits]).to eq(false)
        expect { query.execute }.not_to raise_error
      end
    end
  end

  describe "#explain" do
    it "returns the explaination" do
      ProductIndex.import create(:product)

      query = ProductIndex.match_all.explain(true)
      expect(query.results.first._hit.key?(:_explanation)).to eq(true)
    end
  end

  describe "#custom" do
    it "adds a custom entry to the request" do
      request = ProductIndex.custom(custom_key: "custom_value").request

      expect(request[:custom_key]).to eq("custom_value")
    end
  end

  describe "#preference" do
    it "sets the preference" do
      stub_request(:post, "http://127.0.0.1:9200/products/products/_search?preference=value")
        .to_return(status: 200, headers: { content_type: "application/json" }, body: "{}")

      ProductIndex.preference("value").execute
    end
  end

  describe "#search_type" do
    it "sets the search_type" do
      stub_request(:post, "http://127.0.0.1:9200/products/products/_search?search_type=value")
        .to_return(status: 200, headers: { content_type: "application/json" }, body: "{}")

      ProductIndex.search_type("value").execute
    end
  end

  describe "#routing" do
    it "sets the search_type" do
      stub_request(:post, "http://127.0.0.1:9200/products/products/_search?routing=value")
        .to_return(status: 200, headers: { content_type: "application/json" }, body: "{}")

      ProductIndex.routing("value").execute
    end
  end
end
