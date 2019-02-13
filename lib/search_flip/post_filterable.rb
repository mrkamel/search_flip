
module SearchFlip
  # The SearchFlip::PostFilterable mixin provides chainable methods like
  # #post_where, #post_exists, #post_range, etc to add and apply search
  # filters after aggregations have already been calculated.
  #
  # @example
  #   query = ProductIndex.search("harry potter")
  #
  #   query = query.aggregate(price_ranges: {
  #     range: {
  #       field: "price",
  #       ranges: [
  #         { key: "range1", from: 0,  to: 20 },
  #         { key: "range2", from: 20, to: 50 },
  #         { key: "range3", from: 50, to: 100 }
  #       ]
  #     }
  #   })
  #
  #   query = query.post_where(price: 20 ... 50)

  module PostFilterable
    def self.included(base)
      base.class_eval do
        attr_accessor :post_search_values, :post_must_values, :post_must_not_values, :post_should_values, :post_filter_values
      end
    end

    # Adds a post query string query to the criteria while using AND as the
    # default operator unless otherwise specified. Check out the
    # ElasticSearch docs for further details.
    #
    # @example
    #   CommentIndex.aggregate(:user_id).post_search("message:hello OR message:worl*")
    #
    # @param q [String] The query string query
    #
    # @param options [Hash] Additional options for the query string query, like
    #   eg default_operator, default_field, etc.
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def post_search(q, options = {})
      raise(SearchFlip::NotSupportedError) if SearchFlip.version.to_i < 2

      fresh.tap do |criteria|
        if q.to_s.strip.length > 0
          criteria.post_search_values = (post_search_values || []) + [query_string: { query: q, default_operator: :AND }.merge(options)]
        end
      end
    end

    # Adds post filters to your criteria for the supplied hash composed of
    # field-to-filter mappings which specify terms, term or range filters,
    # depending on the type of the respective hash value, namely array, range
    # or scalar type like Fixnum, String, etc.
    #
    # @example Array values
    #   query = CommentIndex.aggregate("...")
    #   query = query.post_where(id: [1, 2, 3], state: ["approved", "declined"])
    #
    # @example Range values
    #   query = CommentIndex.aggregate("...")
    #   query = query.post_where(created_at: Time.parse("2016-01-01") .. Time.parse("2017-01-01"))
    #
    # @example Scalar types
    #   query = CommentIndex.aggregate("...")
    #   query = query.post_where(id: 1, message: "hello world")
    #
    # @param hash [Hash] A field-to-filter mapping specifying filter values for
    #   the respective fields
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def post_where(hash)
      hash.inject(fresh) do |memo, (key, value)|
        if value.is_a?(Array)
          memo.post_filter terms: { key => value }
        elsif value.is_a?(Range)
          memo.post_filter range: { key => { gte: value.min, lte: value.max } }
        else
          memo.post_filter term: { key => value }
        end
      end
    end

    # Adds post filters to exclude documents in accordance to the supplied hash
    # composed of field-to-filter mappings. Check out #post_where for further
    # details.
    #
    # @example Array values
    #   query = CommentIndex.aggregate("...")
    #   query = query.post_where_not(id: [1, 2, 3])
    #
    # @example Range values
    #   query = CommentIndex.aggregate("...")
    #   query = query.post_where_not(created_at: Time.parse("2016-01-01") .. Time.parse("2017-01-01"))
    #
    # @example
    #   query = CommentIndex.aggregate("...")
    #   query = query.post_where_not(state: "approved")
    #
    # @param hash [Hash] A field-to-filter mapping specifying filter values for the
    #   respective fields
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def post_where_not(hash)
      hash.inject(fresh) do |memo, (key, value)|
        if value.is_a?(Array)
          memo.post_must_not terms: { key => value }
        elsif value.is_a?(Range)
          memo.post_must_not range: { key => { gte: value.min, lte: value.max } }
        else
          memo.post_must_not term: { key => value }
        end
      end
    end

    # Adds raw post filter queries to the criteria.
    #
    # @example Raw post term filter query
    #   query = CommentIndex.aggregate("...")
    #   query = query.post_filter(term: { state: "new" })
    #
    # @example Raw post range filter query
    #   query = CommentIndex.aggregate("...")
    #   query = query.post_filter(range: { created_at: { gte: Time.parse("2016-01-01") }})
    #
    # @param args [Array, Hash] The raw filter query arguments
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def post_filter(*args)
      fresh.tap do |criteria|
        criteria.post_filter_values = (post_filter_values || []) + args
      end
    end

    # Adds raw post must queries to the criteria.
    #
    # @example Raw post term must query
    #   query = CommentIndex.aggregate("...")
    #   query = query.post_must(term: { state: "new" })
    #
    # @example Raw post range must query
    #   query = CommentIndex.aggregate("...")
    #   query = query.post_must(range: { created_at: { gte: Time.parse("2016-01-01") }})
    #
    # @param args [Array, Hash] The raw must query arguments
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def post_must(*args)
      fresh.tap do |criteria|
        criteria.post_must_values = (post_must_values || []) + args
      end
    end

    # Adds raw post must_not queries to the criteria.
    #
    # @example Raw post term must_not query
    #   query = CommentIndex.aggregate("...")
    #   query = query.post_must_not(term: { state: "new" })
    #
    # @example Raw post range must_not query
    #   query = CommentIndex.aggregate("...")
    #   query = query.post_must_not(range: { created_at: { gte: Time.parse("2016-01-01") }})
    #
    # @param args [Array, Hash] The raw must_not query arguments
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def post_must_not(*args)
      fresh.tap do |criteria|
        criteria.post_must_not_values = (post_must_not_values || []) + args
      end
    end

    # Adds raw post should queries to the criteria.
    #
    # @example Raw post term should query
    #   query = CommentIndex.aggregate("...")
    #   query = query.post_should(term: { state: "new" })
    #
    # @example Raw post range should query
    #   query = CommentIndex.aggregate("...")
    #   query = query.post_should(range: { created_at: { gte: Time.parse("2016-01-01") }})
    #
    # @param args [Array, Hash] The raw should query arguments
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def post_should(*args)
      fresh.tap do |criteria|
        criteria.post_should_values = (post_should_values || []) + args
      end
    end

    # Adds a post range filter to the criteria without being forced to specify
    # the left and right end of the range, such that you can eg simply specify
    # lt, lte, gt and gte. For fully specified ranges, you can easily use
    # #post_where, etc. Check out the ElasticSearch docs for further details
    # regarding the range filter.
    #
    # @example
    #   query = CommentIndex.aggregate("...")
    #   query = query.post_range(:created_at, gte: Time.parse("2016-01-01"))
    #
    #   query = CommentIndex.aggregate("...")
    #   query = query.post_range(:likes_count, gt: 10, lt: 100)
    #
    # @param field [Symbol, String] The field name to specify the range for
    # @param options [Hash] The range filter specification, like lt, lte, etc
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def post_range(field, options = {})
      post_filter range: { field => options }
    end

    # Adds a post exists filter to the criteria, which selects all documents
    # for which the specified field has a non-null value.
    #
    # @example
    #   query = CommentIndex.aggregate("...")
    #   query = query.post_exists(:notified_at)
    #
    # @param field [Symbol, String] The field that should have a non-null value
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def post_exists(field)
      post_filter exists: { field: field }
    end

    # Adds a post exists not filter to the criteria, which selects all documents
    # for which the specified field's value is null.
    #
    # @example
    #   query = CommentIndex.aggregate("...")
    #   query = query.post_exists_not(:notified_at)
    #
    # @param field [Symbol, String] The field that should have a null value
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def post_exists_not(field)
      post_must_not exists: { field: field }
    end
  end
end

