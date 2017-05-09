
module ElasticSearch
  # The ElasticSearch::AggregationRelation class puts together everything
  # required to use the ElasticSearch aggregation framework via mixins and
  # adds a method to convert it to a hash format to be used in the request.

  class AggregationRelation
    include ElasticSearch::FilterableRelation
    include ElasticSearch::AggregatableRelation

    # @api private
    #
    # Converts the aggregation to a hash format that can be used in the request.
    #
    # @return [Hash] A hash version of the aggregation

    def to_hash
      res = {}
      res[:aggregations] = aggregation_values if aggregation_values.present?
      res[:filter] = filter_values.size > 1 ? { and: filter_values } : filter_values.first if filter_values.present?
      res
    end

    # @api private
    #
    # Simply dups the object for api compatability.
    #
    # @return [ElasticSearch::AggregationRelation] The dupped object

    def fresh
      dup
    end
  end
end

