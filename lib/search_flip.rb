
require "forwardable"
require "http"
require "hashie"
require "oj"
require "set"

require "search_flip/version"
require "search_flip/exceptions"
require "search_flip/json"
require "search_flip/http_client"
require "search_flip/config"
require "search_flip/bulk"
require "search_flip/filterable"
require "search_flip/post_filterable"
require "search_flip/aggregatable"
require "search_flip/aggregation"
require "search_flip/criteria"
require "search_flip/response"
require "search_flip/result"
require "search_flip/index"
require "search_flip/model"

module SearchFlip
  class NotSupportedError < StandardError; end
  class ConnectionError < StandardError; end

  class ResponseError < StandardError
    attr_reader :code, :body

    def initialize(code:, body:)
      @code = code
      @body = body
    end

    def to_s
      "#{self.class.name} (#{code}): #{body}"
    end
  end

  # Uses the ElasticSearch Multi Search API to execute multiple search requests
  # within a single request. Raises SearchFlip::ResponseError in case any
  # errors occur.
  #
  # @example
  #   SearchFlip.msearch [ProductIndex.match_all, CommentIndex.match_all]
  #
  # @param criterias [Array<SearchFlip::Criteria>] An array of search
  #   queries to execute in parallel
  # @param base_url [String] The Elasticsearch base url
  #
  # @return [Array<SearchFlip::Response>] An array of responses

  def self.msearch(criterias, base_url: SearchFlip::Config[:base_url])
    payload = criterias.flat_map do |criteria|
      [
        SearchFlip::JSON.generate(index: criteria.target.index_name_with_prefix, type: criteria.target.type_name),
        SearchFlip::JSON.generate(criteria.request)
      ]
    end

    payload = payload.join("\n")
    payload << "\n"

    raw_response =
      SearchFlip::HTTPClient
        .headers(accept: "application/json", content_type: "application/x-ndjson")
        .post("#{base_url}/_msearch", body: payload)

    raw_response.parse["responses"].map.with_index do |response, index|
      SearchFlip::Response.new(criterias[index], response)
    end
  end

  # Used to manipulate, ie add and remove index aliases. Raises an
  # SearchFlip::ResponseError in case any errors occur.
  #
  # @example
  #   SearchFlip.update_aliases(actions: [
  #     { remove: { index: "test1", alias: "alias1" }},
  #     { add: { index: "test2", alias: "alias1" }}
  #   ])
  #
  # @param payload [Hash] The raw request payload
  # @param base_url [String] The Elasticsearch base url
  #
  # @return [Hash] The raw response

  def self.update_aliases(payload, base_url: SearchFlip::Config[:base_url])
    SearchFlip::HTTPClient
      .headers(accept: "application/json", content_type: "application/json")
      .post("#{base_url}/_aliases", body: SearchFlip::JSON.generate(payload))
      .parse
  end

  def self.aliases(payload)
    warn "[DEPRECATION] `SearchFlip.aliases` is deprecated. Please use `SearchFlip.update_aliases` instead."

    update_aliases(payload)
  end

  # Fetches information about the specified index aliases. Raises
  # SearchFlip::ResponseError in case any errors occur.
  #
  # @example
  #   SearchFlip.get_aliases(alias_name: "some_alias")
  #   SearchFlip.get_aliases(index_name: "index1,index2")
  #
  # @param alias_name [String] The alias or comma separated list of alias names
  # @param index_name [String] The index or comma separated list of index names
  # @param base_url [String] The Elasticsearch base url
  #
  # @return [Hash] The raw response

  def self.get_aliases(index_name: "*", alias_name: "*", base_url: SearchFlip::Config[:base_url])
    SearchFlip::HTTPClient
      .headers(accept: "application/json", content_type: "application/json")
      .get("#{base_url}/#{index_name}/_alias/#{alias_name}")
      .parse
  end

  # Returns whether or not the associated ElasticSearch alias already
  # exists.
  #
  # @example
  #   SearchFlip.alias_exists?("some_alias")
  #
  # @return [Boolean] Whether or not the alias exists

  def self.alias_exists?(alias_name, base_url: SearchFlip::Config[:base_url])
    get_aliases(alias_name: alias_name, base_url: base_url)

    true
  rescue SearchFlip::ResponseError => e
    return false if e.code == 404

    raise e
  end
end

