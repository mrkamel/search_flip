
module Searchist
  # Queries and returns the ElasticSearch server version used.
  #
  # @example
  #   Searchist.version # => e.g. 2.4.1
  #
  # @return [String] The Searchist server version

  def self.version
    @version ||= Searchist::HTTPClient.get("#{Config[:base_url]}/").parse["version"]["number"]
  end

  Config = {
    index_prefix: nil,
    base_url: "http://127.0.0.1:9200",
    bulk_limit: 1_000,
    auto_refresh: false
  }
end

