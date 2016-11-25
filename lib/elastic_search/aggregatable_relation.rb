
module ElasticSearch
  module AggregatableRelation
    def self.included(base)
      base.class_eval do
        attr_accessor :aggregation_values
      end
    end

    def aggregate(field_or_hash, options = {}, &block)
      fresh.tap do |relation|
        hash = field_or_hash.is_a?(Hash) ? field_or_hash : { field_or_hash => { terms: { field: field_or_hash }.merge(options) } }

        if block
          aggregation_relation = block.call(ElasticSearch::AggregationRelation.new)

          field_or_hash.is_a?(Hash) ? hash[field_or_hash.keys.first].merge!(aggregation_relation.to_hash) : hash[field_or_hash].merge!(aggregation_relation.to_hash)
        end

        relation.aggregation_values = (aggregation_values || {}).merge(hash)
      end
    end
  end
end

