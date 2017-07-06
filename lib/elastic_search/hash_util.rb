
require "set"

module ElasticSearch
  class HashUtil
    def initialize(hash)
      @hash = hash
    end

    def except(*keys)
      key_set = keys.to_set

      @hash.dup.delete_if { |key, _| key_set.include?(key) }
    end
  end
end

