
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
        attr_accessor :search_values, :must_values, :must_not_values, :should_values, :filter_values
      end
    end

    # Adds a query string query to the criteria while using AND as the default
    # operator unless otherwise specified. Check out the ElasticSearch docs
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
      fresh.tap do |criteria|
        if q.to_s.strip.length > 0
          criteria.search_values = (search_values || []) + [query_string: { query: q, default_operator: :AND }.merge(options)]
        end
      end
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
          memo.filter terms: { key => value }
        elsif value.is_a?(Range)
          memo.filter range: { key => { gte: value.min, lte: value.max } }
        elsif value.nil?
          memo.exists_not key
        else
          memo.filter term: { key => value }
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
          memo.must_not terms: { key => value }
        elsif value.is_a?(Range)
          memo.must_not range: { key => { gte: value.min, lte: value.max } }
        elsif value.nil?
          memo.exists key
        else
          memo.must_not term: { key => value }
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

    def filter(*args)
      fresh.tap do |criteria|
        criteria.filter_values = (filter_values || []) + args
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

    def must(*args)
      fresh.tap do |criteria|
        criteria.must_values = (must_values || []) + args
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

    def must_not(*args)
      fresh.tap do |criteria|
        criteria.must_not_values = (must_not_values || []) + args
      end
    end

    # Adds raw should queries to the criteria.
    #
    # @example
    #   CommentIndex.should(term: { state: "new" })
    #   CommentIndex.should(range: { created_at: { gt: Time.parse"2016-01-01") }})
    #
    # @param args [Array, Hash] The raw should query arguments
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def should(*args)
      fresh.tap do |criteria|
        criteria.should_values = (should_values || []) + args
      end
    end

    # Adds a range filter to the criteria without being forced to specify the
    # left and right end of the range, such that you can eg simply specify lt,
    # lte, gt and gte. For fully specified ranges, you can as well use #where,
    # etc. Check out the ElasticSearch docs for further details regarding the
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
      filter range: { field => options }
    end

    # Adds a match all filter/query to the criteria, which simply matches all
    # documents. This can be eg be used within filter aggregations or for
    # filter chaining. Check out the ElasticSearch docs for further details.
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
      filter match_all: options
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
      filter exists: { field: field }
    end

    # Adds an exists not filter to the criteria, which selects all documents
    # for which the specified field's value is null.
    #
    # @example
    #   CommentIndex.exists_not(:notified_at)
    #
    # @param field [Symbol, String] The field that should have a null value
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def exists_not(field)
      must_not exists: { field: field }
    end
  end
end

