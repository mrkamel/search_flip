
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

      if filter_values || filter_not_values
        if ElasticSearch.version.to_i >= 2
          res[:filter] = { bool: {}.merge(filter_not_values ? { must_not: filter_not_values } : {}).merge(filter_values ? { filter: filter_values } : {}) }
        else
          filters = (filter_values || []) + (filter_not_values || []).map { |filter_not_value| { not: filter_not_value } }

          res[:filter] = filters.size > 1 ? { and: filters } : filters.first
        end
      end

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

