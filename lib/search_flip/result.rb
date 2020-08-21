module SearchFlip
  # The SearchFlip::Result class basically is a hash wrapper that uses
  # Hashie::Mash to provide convenient method access to the hash attributes.

  class Result < Hashie::Mash
    def self.disable_warnings?(*args)
      true
    end

    # Creates a SearchFlip::Result object from a raw hit. Useful for e.g.
    # top hits aggregations.
    #
    # @example
    #   query = ProductIndex.aggregate(top_sales: { top_hits: "..." })
    #   top_sales_hits = query.aggregations(:top_sales).top_hits.hits.hits
    #
    #   SearchFlip::Result.from_hit(top_sales_hits.first)

    def self.from_hit(hit)
      raw_result = (hit["_source"] || {}).dup

      raw_result["_hit"] = hit.each_with_object({}) do |(key, value), hash|
        hash[key] = value if key != "_source"
      end

      new(raw_result)
    end
  end
end
