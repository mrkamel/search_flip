module SearchFlip
  # The SearchFlip::Result class is a simple Hash, but extended with
  # method-like access. Keys assigned via methods are stored as strings.
  #
  # @example method access
  #   result = SearchFlip::Result.new
  #   result["some_key"] = "value"
  #   result.some_key # => "value"

  class Result < Hash
    def self.convert(hash)
      res = self[hash]

      res.each do |key, value|
        if value.is_a?(Hash)
          res[key] = convert(value)
        elsif value.is_a?(Array)
          res[key] = convert_array(value)
        end
      end

      res
    end

    def self.convert_array(arr)
      arr.map do |obj|
        if obj.is_a?(Hash)
          convert(obj)
        elsif obj.is_a?(Array)
          convert_array(obj)
        else
          obj
        end
      end
    end

    # rubocop:disable Style/MethodMissingSuper

    def method_missing(name, *args, &block)
      self[name.to_s]
    end

    # rubocop:enable Style/MethodMissingSuper

    def respond_to_missing?(name, include_private = false)
      key?(name.to_s) || super
    end

    def self.from_hit(hit)
      res = convert(hit["_source"] || {})
      res["_hit"] = convert(self[hit].tap { |hash| hash.delete("_source") })
      res
    end
  end
end
