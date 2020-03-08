module SearchFlip
  # The SearchFlip::Filterable mixin provides chainable methods like
  # #where, #exists, #range, etc to add search filters to a criteria.
  #
  # @example
  #   CommentIndex.where(public: true)
  #   CommentIndex.exists(:user_id)
  #   CommentIndex.range(:created_at, gt: Date.today - 7)

  module Filterable
    def self.included(base)
      base.class_eval do
        attr_accessor :must_values, :must_not_values, :filter_values
      end
    end

    # Adds a query string query to the criteria while using AND as the default
    # operator unless otherwise specified. Check out the Elasticsearch docs
    # for further details.
    #
    # @example
    #   CommentIndex.search("message:hello OR message:worl*")
    #
    # @param q [String] The query string query
    #
    # @param options [Hash] Additional options for the query string query, like
    #   eg default_operator, default_field, etc.
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def search(q, options = {})
      return self if q.to_s.strip.length.zero?

      must(query_string: { query: q, default_operator: :AND }.merge(options))
    end

    # Adds filters to your criteria for the supplied hash composed of
    # field-to-filter mappings which specify terms, term or range filters,
    # depending on the type of the respective hash value, namely array, range
    # or scalar type like Fixnum, String, etc.
    #
    # @example
    #   CommentIndex.where(id: [1, 2, 3], state: ["approved", "declined"])
    #   CommentIndex.where(id: 1 .. 100)
    #   CommentIndex.where(created_at: Time.parse("2016-01-01") .. Time.parse("2017-01-01"))
    #   CommentIndex.where(id: 1, message: "hello")
    #   CommentIndex.where(state: nil)
    #
    # @param hash [Hash] A field-to-filter mapping specifying filter values for
    #   the respective fields
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def where(hash)
      hash.inject(fresh) do |memo, (key, value)|
        if value.is_a?(Array)
          memo.filter(terms: { key => value })
        elsif value.is_a?(Range)
          memo.filter(range: { key => { gte: value.min, lte: value.max } })
        elsif value.nil?
          memo.must_not(exists: { field: key })
        else
          memo.filter(term: { key => value })
        end
      end
    end

    # Adds filters to exclude documents in accordance to the supplied hash
    # composed of field-to-filter mappings. Check out #where for further
    # details.
    #
    # @see #where See #where for further details
    #
    # @example
    #   CommentIndex.where_not(state: "approved")
    #   CommentIndex.where_not(created_at: Time.parse("2016-01-01") .. Time.parse("2017-01-01"))
    #   CommentIndex.where_not(id: [1, 2, 3], state: "new")
    #   CommentIndex.where_not(state: nil)
    #
    # @param hash [Hash] A field-to-filter mapping specifying filter values for the
    #   respective fields
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def where_not(hash)
      hash.inject(fresh) do |memo, (key, value)|
        if value.is_a?(Array)
          memo.must_not(terms: { key => value })
        elsif value.is_a?(Range)
          memo.must_not(range: { key => { gte: value.min, lte: value.max } })
        elsif value.nil?
          memo.filter(exists: { field: key })
        else
          memo.must_not(term: { key => value })
        end
      end
    end

    # Adds raw filter queries to the criteria.
    #
    # @example
    #   CommentIndex.filter(term: { state: "new" })
    #   CommentIndex.filter(range: { created_at: { gte: Time.parse("2016-01-01") }})
    #
    # @param args [Array, Hash] The raw filter query arguments
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def filter(clause)
      fresh.tap do |criteria|
        criteria.filter_values = (filter_values || []) + Helper.wrap_array(clause)
      end
    end

    # Adds raw must queries to the criteria.
    #
    # @example
    #   CommentIndex.must(term: { state: "new" })
    #   CommentIndex.must(range: { created_at: { gt: Time.parse("2016-01-01") }})
    #
    # @param args [Array, Hash] The raw must query arguments
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def must(clause, bool_options = {})
      fresh.tap do |criteria|
        criteria.must_values = (must_values || []) + Helper.wrap_array(clause)
      end
    end

    # Adds raw must_not queries to the criteria.
    #
    # @example
    #   CommentIndex.must_not(term: { state: "new" })
    #   CommentIndex.must_not(range: { created_at: { gt: Time.parse"2016-01-01") }})
    #
    # @param args [Array, Hash] The raw must_not query arguments
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def must_not(clause)
      fresh.tap do |criteria|
        criteria.must_not_values = (must_not_values || []) + Helper.wrap_array(clause)
      end
    end

    # Returns all added queries and filters, including post filters, as a raw
    # query and in query (score) mode.
    #
    # @example Basic usage
    #   CommentIndex.where(state: "new").post_range(:likes_count, gt: 10).to_query
    #   # => {:bool=>{:must=>[{:term=>{:state=>"new"}}, {:range=>{:likes_count=>{:gt=>10}}}]}}
    #
    # @example Usage with should clauses
    #   CommentIndex.should([
    #     CommentIndex.range(:likes_count, gt: 10),
    #     CommentIndex.search("search term")
    #   ])
    #
    # @return [Hash] The raw query

    def to_query
      {
        bool: {
          must: must_values.to_a + post_must_values.to_a + filter_values.to_a + post_filter_values.to_a,
          must_not: must_not_values.to_a + post_must_not_values.to_a
        }.reject { |_, value| value.empty? }
      }
    end

    # Like `to_query` the `to_filter` method returns all added queries and
    # filters, including post filters, as a raw query, but in filter mode
    # instead of query (score) mode.
    #
    # @example
    #   CommentIndex.where(state: "new").post_range(:likes_count, gt: 10).to_filter
    #   # => {:bool=>{:filter=>[{:term=>{:state=>"new"}}, {:range=>{:likes_count=>{:gt=>10}}}]}}
    #
    # @return [Hash] The raw filter query

    def to_filter
      {
        bool: {
          must_not: must_not_values.to_a + post_must_not_values.to_a,
          filter: must_values.to_a + post_must_values.to_a + filter_values.to_a + post_filter_values.to_a
        }.reject { |_, value| value.empty? }
      }
    end

    # Adds a raw should query to the criteria.
    #
    # @example
    #   CommentIndex.should(
    #     [
    #       { term: { state: "new" } },
    #       { term: { state: "reviewed" } }
    #     ],
    #     boost: 5
    #   )
    #
    # @param args [Array] The raw should query arguments
    # @param bool_options [Hash] An optional hash with options for the
    #   resulting bool query like `boost` or `minimum_should_match`
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def should(clause, bool_options = {})
      must(bool: bool_options.merge(should: clause))
    end

    # Adds a range filter to the criteria without being forced to specify the
    # left and right end of the range, such that you can eg simply specify lt,
    # lte, gt and gte. For fully specified ranges, you can as well use #where,
    # etc. Check out the Elasticsearch docs for further details regarding the
    # range filter.
    #
    # @example
    #   CommentIndex.range(:created_at, gte: Time.parse("2016-01-01"))
    #   CommentIndex.range(:likes_count, gt: 10, lt: 100)
    #
    # @param field [Symbol, String] The field name to specify the range for
    # @param options [Hash] The range filter specification, like lt, lte, etc
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def range(field, options = {})
      filter(range: { field => options })
    end

    # Adds a match all filter to the criteria, which simply matches all
    # documents. This can be eg be used within filter aggregations or for
    # filter chaining. Check out the Elasticsearch docs for further details.
    #
    # @example Basic usage
    #   CommentIndex.match_all
    #
    # @example Filter chaining
    #   query = CommentIndex.match_all
    #   query = query.where(public: true) unless current_user.admin?
    #
    # @example Filter aggregation
    #   query = CommentIndex.aggregate(filtered_tags: {}) do |aggregation|
    #     aggregation = aggregation.match_all
    #     aggregation = aggregation.where(user_id: current_user.id) if current_user
    #     aggregation = aggregation.aggregate(:tags)
    #   end
    #
    #   query.aggregations(:filtered_tags).tags.buckets.each { ... }
    #
    # @param options [Hash] Options for the match_all filter, like eg boost
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def match_all(options = {})
      filter(match_all: options)
    end

    # Adds an exists filter to the criteria, which selects all documents for
    # which the specified field has a non-null value.
    #
    # @example
    #   CommentIndex.exists(:notified_at)
    #
    # @param field [Symbol, String] The field that should have a non-null value
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def exists(field)
      filter(exists: { field: field })
    end

    # Adds an exists not query to the criteria, which selects all documents
    # for which the specified field's value is null.
    #
    # @example
    #   CommentIndex.exists_not(:notified_at)
    #
    # @param field [Symbol, String] The field that should have a null value
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def exists_not(field)
      must_not(exists: { field: field })
    end
  end
end
