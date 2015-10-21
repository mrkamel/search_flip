
require File.expand_path("../filterable_relation", __FILE__)
require File.expand_path("../aggregatable_relation", __FILE__)

module ElasticSearch
  class AggregationRelation
    include ElasticSearch::FilterableRelation
    include ElasticSearch::AggregatableRelation

    def to_hash
      res = {}
      res[:aggregations] = aggregation_values if aggregation_values.present?
      res[:filter] = { :and => filter_values } if filter_values.present?
      res
    end

    def clear_cache!
      # Nothing
    end
  end
end

