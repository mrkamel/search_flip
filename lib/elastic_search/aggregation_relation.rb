
module ElasticSearch
  class AggregationRelation
    include ElasticSearch::FilterableRelation
    include ElasticSearch::AggregatableRelation

    def to_hash
      res = {}
      res[:aggregations] = aggregation_values if aggregation_values.present?
      res[:filter] = filter_values.size > 1 ? { :and => filter_values } : filter_values.first if filter_values.present?
      res
    end

    def fresh
      dup
    end
  end
end

