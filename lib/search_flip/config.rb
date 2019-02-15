
module SearchFlip
  Config = {
    index_prefix: nil,
    base_url: "http://127.0.0.1:9200",
    bulk_limit: 1_000,
    auto_refresh: false
  }

  # Queries and returns the ElasticSearch version used.
  #
  # @example
  #   SearchFlip.version # => e.g. 2.4.1
  #
  # @return [String] The ElasticSearch version

  def self.version(base_url: SearchFlip::Config[:base_url])
    @version ||= SearchFlip::HTTPClient.get("#{base_url}/").parse["version"]["number"]
  end
end

