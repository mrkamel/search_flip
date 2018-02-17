
require "forwardable"
require "http"
require "hashie"
require "set"

require "search_flip/version"
require "search_flip/http_client"
require "search_flip/config"
require "search_flip/bulk"
require "search_flip/filterable_criteria"
require "search_flip/post_filterable_criteria"
require "search_flip/aggregatable_criteria"
require "search_flip/aggregation_criteria"
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
  #
  # @return [Array<SearchFlip::Response>] An array of responses

  def self.msearch(criterias)
    payload = criterias.flat_map do |criteria|
      [JSON.generate(index: criteria.target.index_name_with_prefix, type: criteria.target.type_name), JSON.generate(criteria.request)]
    end

    payload = payload.join("\n")
    payload << "\n"

    SearchFlip::HTTPClient.headers(accept: "application/json", content_type: "application/x-ndjson").post("#{SearchFlip::Config[:base_url]}/_msearch", body: payload).parse["responses"].map.with_index do |response, index|
      SearchFlip::Response.new(criterias[index], response)
    end
  end
end

