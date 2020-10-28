module SearchFlip
  # The SearchFlip::JsonHash class is a simple Hash, but extended with
  # method-like access. Keys assigned via methods are stored as strings.
  #
  # @example
  #   result = SearchFlip::JsonHash.new
  #   result["some_key"] = "value"
  #   result.some_key # => "value"

  class JsonHash < Hash
    # rubocop:disable Lint/MissingSuper

    def method_missing(name, *args, &block)
      self[name.to_s]
    end

    def respond_to_missing?(name, include_private = false)
      key?(name.to_s)
    end

    # rubocop:enable Lint/MissingSuper
  end
end
