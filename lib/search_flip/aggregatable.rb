
module SearchFlip
  # The SearchFlip::Aggregatable mixin provides handy methods for using
  # the ElasticSearch aggregation framework, which can be chained with
  # each other, all other criteria methods and even nested.
  #
  # @example
  #   ProductIndex.where(available: true).aggregate(:tags, size: 50)
  #   OrderIndex.aggregate(revenue: { sum: { field: "price" }})

  module Aggregatable
    def self.included(base)
      base.class_eval do
        attr_accessor :aggregation_values
      end
    end

    # Adds an arbitrary aggregation to the request which can be chained as well
    # as nested. Check out the examples and ElasticSearch docs for further
    # details.
    #
    # @example Basic usage with optons
    #   query = CommentIndex.where(public: true).aggregate(:user_id, size: 100)
    #
    #   query.aggregations(:user_id)
    #   # => { 4 => #<SearchFlip::Result ...>, 7 => #<SearchFlip::Result ...>, ... }
    #
    # @example Simple range aggregation
    #   ranges = [{ to: 50 }, { from: 50, to: 100 }, { from: 100 }]
    #
    #   ProductIndex.aggregate(price_range: { range: { field: "price", ranges: ranges }})
    #
    # @example Basic nested aggregation
    #   # When nesting aggregations, the return value of the aggregate block is
    #   # used.
    #
    #   OrderIndex.aggregate(:user_id, order: { revenue: "desc" }) do |aggregation|
    #     aggregation.aggregate(revenue: { sum: { field: "price" }})
    #   end
    #
    # @example Nested histogram aggregation
    #   OrderIndex.aggregate(histogram: { date_histogram: { field: "price", interval: "month" }}) do |aggregation|
    #     aggregation.aggregate(:user_id)
    #   end
    #
    # @example Nested aggregation with filters
    #   OrderIndex.aggregate(average_price: {}) do |aggregation|
    #     aggregation = aggregation.match_all
    #     aggregation = aggregation.where(user_id: current_user.id) if current_user
    #
    #     aggregation.aggregate(average_price: { avg: { field: "price" }})
    #   end

    def aggregate(field_or_hash, options = {}, &block)
      fresh.tap do |criteria|
        hash = field_or_hash.is_a?(Hash) ? field_or_hash : { field_or_hash => { terms: { field: field_or_hash }.merge(options) } }

        if block
          aggregation = yield(SearchFlip::Aggregation.new)

          field_or_hash.is_a?(Hash) ? hash[field_or_hash.keys.first].merge!(aggregation.to_hash) : hash[field_or_hash].merge!(aggregation.to_hash)
        end

        criteria.aggregation_values = (aggregation_values || {}).merge(hash)
      end
    end
  end
end

