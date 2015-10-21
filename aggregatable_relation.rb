
module ElasticSearch
  module AggregatableRelation
    def self.included(base)
      base.class_eval do
        attr_accessor :aggregation_values
      end
    end

    def aggregate!(field_or_hash, options = {}, &block)
      clear_cache!

      hash = field_or_hash.is_a?(Hash) ? field_or_hash : { field_or_hash => { :terms => { :field => field_or_hash }.merge(options) } }

      if block
        relation = ElasticSearch::AggregationRelation.new
        block.call relation

        field_or_hash.is_a?(Hash) ? hash[field_or_hash.keys.first].merge!(relation.to_hash) : hash[field_or_hash].merge!(relation.to_hash)
      end

      self.aggregation_values = (aggregation_values || {}).merge(hash)
      self
    end

    def aggregate(field_or_hash, options = {}, &block)
      dup.tap do |relation|
        relation.aggregate!(field_or_hash, options, &block)
      end
    end
  end
end

