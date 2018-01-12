
module Searchist
  # The Searchist::FilterableRelation mixin provides chainable methods like
  # #where, #exists, #range, etc to add search filters to a relation.
  #
  # @example
  #   CommentIndex.where(public: true)
  #   CommentIndex.exists(:user_id)
  #   CommentIndex.range(:created_at, gt: Date.today - 7)

  module FilterableRelation
    def self.included(base)
      base.class_eval do
        attr_accessor :search_values, :must_values, :must_not_values, :should_values, :filter_values
      end
    end

    # Adds a query string query to the relation while using AND as the default
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
    # @return [Searchist::Relation] A newly created extended relation

    def search(q, options = {})
      fresh.tap do |relation|
        relation.search_values = (search_values || []) + [query_string: { query: q, :default_operator => :AND }.merge(options)] if q.to_s.strip.length > 0
      end
    end

    # Adds filters to your relation for the supplied hash composed of
    # field-to-filter mappings which specify terms, term or range filters,
    # depending on the type of the respective hash value, namely array, range
    # or scalar type like Fixnum, String, etc.
    #
    # @example
    #   CommentIndex.where(id: [1, 2, 3], state: ["approved", "declined"])
    #   CommentIndex.where(id: 1 .. 100)
    #   CommentIndex.where(created_at: Time.parse("2016-01-01") .. Time.parse("2017-01-01"))
    #   CommentIndex.where(id: 1, message: "hello")
    #
    # @param hash [Hash] A field-to-filter mapping specifying filter values for
    #   the respective fields
    #
    # @return [Searchist::Relation] A newly created extended relation

    def where(hash)
      hash.inject(fresh) do |memo, (key, value)|
        if value.is_a?(Array)
          memo.filter terms: { key => value }
        elsif value.is_a?(Range)
          memo.filter range: { key => { gte: value.min, lte: value.max } }
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
    #
    # @param hash [Hash] A field-to-filter mapping specifying filter values for the
    #   respective fields
    #
    # @return [Searchist::Relation] A newly created extended relation

    def where_not(hash)
      hash.inject(fresh) do |memo, (key, value)|
        if value.is_a?(Array)
          memo.must_not terms: { key => value }
        elsif value.is_a?(Range)
          memo.must_not range: { key => { gte: value.min, lte: value.max } }
        else
          memo.must_not term: { key => value }
        end
      end
    end

    # Adds raw filter queries to the relation.
    #
    # @example
    #   CommentIndex.filter(term: { state: "new" })
    #   CommentIndex.filter(range: { created_at: { gte: Time.parse("2016-01-01") }})
    #
    # @param args [Array, Hash] The raw filter query arguments
    #
    # @return [Searchist::Relation] A newly created extended relation

    def filter(*args)
      fresh.tap do |relation|
        relation.filter_values = (filter_values || []) + args
      end
    end

    # Adds raw must queries to the relation.
    #
    # @example
    #   CommentIndex.must(term: { state: "new" })
    #   CommentIndex.must(range: { created_at: { gt: Time.parse("2016-01-01") }})
    #
    # @param args [Array, Hash] The raw must query arguments
    #
    # @return [Searchist::Relation] A newly created extended relation

    def must(*args)
      fresh.tap do |relation|
        relation.must_values = (must_values || []) + args
      end
    end

    # Adds raw must_not queries to the relation.
    #
    # @example
    #   CommentIndex.must_not(term: { state: "new" })
    #   CommentIndex.must_not(range: { created_at: { gt: Time.parse"2016-01-01") }})
    #
    # @param args [Array, Hash] The raw must_not query arguments
    #
    # @return [Searchist::Relation] A newly created extended relation

    def must_not(*args)
      fresh.tap do |relation|
        relation.must_not_values = (must_not_values || []) + args
      end
    end

    # Adds raw should queries to the relation.
    #
    # @example
    #   CommentIndex.should(term: { state: "new" })
    #   CommentIndex.should(range: { created_at: { gt: Time.parse"2016-01-01") }})
    #
    # @param args [Array, Hash] The raw should query arguments
    #
    # @return [Searchist::Relation] A newly created extended relation

    def should(*args)
      fresh.tap do |relation|
        relation.should_values = (should_values || []) + args
      end
    end

    # Adds a range filter to the relation without being forced to specify the
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
    # @return [Searchist::Relation] A newly created extended relation

    def range(field, options = {})
      filter range: { field => options }
    end

    # Adds a match all filter/query to the relation, which simply matches all
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
    # @return [Searchist::Relation] A newly created extended relation

    def match_all(options = {})
      filter match_all: options
    end

    # Adds an exists filter to the relation, which selects all documents for
    # which the specified field has a non-null value.
    #
    # @example
    #   CommentIndex.exists(:notified_at)
    #
    # @param field [Symbol, String] The field that should have a non-null value
    #
    # @return [Searchist::Relation] A newly created extended relation

    def exists(field)
      filter exists: { field: field }
    end

    # Adds an exists not filter to the relation, which selects all documents
    # for which the specified field's value is null.
    #
    # @example
    #   CommentIndex.exists_not(:notified_at)
    #
    # @param field [Symbol, String] The field that should have a null value
    #
    # @return [Searchist::Relation] A newly created extended relation

    def exists_not(field)
      must_not exists: { field: field }
    end
  end
end

