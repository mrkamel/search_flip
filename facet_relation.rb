
require File.expand_path("../filterable_relation", __FILE__)
require File.expand_path("../facetable_relation", __FILE__)

module ElasticSearch
  class FacetRelation
    include ElasticSearch::FilterableRelation
    include ElasticSearch::FacetableRelation

    def to_hash
      res = {}
      res[:facet_filter] = { :and => filter_values } if filter_values.present?
      res
    end

    def clear_cache!
      # Nothing
    end
  end
end

