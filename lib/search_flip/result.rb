module SearchFlip
  # The SearchFlip::Result class is a simple Hash, but extended with
  # method-like access. Keys assigned via methods are stored as strings.
  # It represents a result, i.e. a document and provides methods to convert
  # elasticsearch hit objects to those.
  #
  # @example method access
  #   result = SearchFlip::Result.new
  #   result["some_key"] = "value"
  #   result.some_key # => "value"

  class Result < JsonHash
    def self.from_hit(hit)
      raw_result = self[hit["_source"] || {}]
      raw_result["_hit"] = JsonHash[hit].tap { |json_hash| json_hash.delete("_source") }
      raw_result
    end
  end
end
