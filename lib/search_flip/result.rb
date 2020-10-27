module SearchFlip
  # The SearchFlip::Result class is a simple Hash, but extended with
  # method-like access. Keys assigned via methods are stored as strings.
  #
  # @example
  #   result = SearchFlip::Result.new
  #   result["some_key"] = "value"
  #   result.some_key # => "value"

  class Result < Hash
    def method_missing(name, *args, &block)
      self[name.to_s]
    end

    def respond_to_missing?(name, include_private = false)
      key?(name.to_s)
    end
  end
end
