
module ElasticSearch
  class FacetRelation
    include ElasticSearch::FilterableRelation
    include ElasticSearch::FacetableRelation

    def to_hash
      res = {}
      res[:facet_filter] = filter_values.size > 1 ? { :and => filter_values } : filter_values.first if filter_values.present?
      res
    end

    def clear_cache!
      # Nothing
    end
  end
end

