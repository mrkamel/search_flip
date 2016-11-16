
module ElasticSearch
  def self.version
    @version ||= JSON.parse(RestClient.get("#{Config[:base_url]}/", content_type: "application/json"))["version"]["number"]
  end

  Config = {
    index_prefix: nil,
    base_url: "http://127.0.0.1:9200",
    bulk_limit: 1_000,
    environment: "development"
  }
end

