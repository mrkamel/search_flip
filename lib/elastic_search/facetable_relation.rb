
module ElasticSearch
  module FacetableRelation
    def self.included(base)
      base.class_eval do
        attr_accessor :facet_values
      end
    end

    def facet!(field_or_hash, options = {}, &block)
      clear_cache!

      hash = field_or_hash.is_a?(Hash) ? field_or_hash : { field_or_hash => { :terms => { :field => field_or_hash }.merge(options) } }

      if block
        relation = ElasticSearch::FacetRelation.new

        block.call(relation)

        field_or_hash.is_a?(Hash) ? hash[field_or_hash.keys.first].merge!(relation.to_hash) : hash[field_or_hash].merge!(relation.to_hash)
      end

      self.facet_values = (facet_values || {}).merge(hash)
      self
    end

    def facet(field_or_hash, options = {}, &block)
      dup.tap do |relation|
        relation.facet!(field_or_hash, options, &block)
      end
    end
  end
end

