
require "forwardable"
require "http"
require "hashie"
require "set"

require "elastic_search/version"
require "elastic_search/http_client"
require "elastic_search/config"
require "elastic_search/bulk"
require "elastic_search/filterable_relation"
require "elastic_search/post_filterable_relation"
require "elastic_search/aggregatable_relation"
require "elastic_search/aggregation_relation"
require "elastic_search/relation"
require "elastic_search/response"
require "elastic_search/result"
require "elastic_search/index"
require "elastic_search/model"

module ElasticSearch
  class NotSupportedError < StandardError; end
  class ConnectionError < StandardError; end

  class ResponseError < StandardError
    attr_reader :code, :body

    def initialize(code:, body:)
      @code = code
      @body = body
    end

    def to_s
      "#{self.class.name} (#{code})"
    end
  end

  # Uses the ElasticSearch Multi Search API to execute multiple search requests
  # within a single request. Raises ElasticSearch::ResponseError in case any
  # errors occur.
  #
  # @example
  #   ElasticSearch.msearch [ProductIndex.match_all, CommentIndex.match_all]
  #
  # @param relations [Array<ElasticSearch::Relation>] An array of search
  #   queries to execute in parallel
  #
  # @return [Array<ElasticSearch::Response>] An array of responses

  def self.msearch(relations)
    payload = relations.flat_map do |relation|
      [JSON.generate(index: relation.target.index_name_with_prefix, type: relation.target.type_name), JSON.generate(relation.request)]
    end

    payload = payload.join("\n")
    payload << "\n"

    ElasticSearch::HTTPClient.headers(accept: "application/json", content_type: "application/x-ndjson").post("#{ElasticSearch::Config[:base_url]}/_msearch", body: payload).parse["responses"].map.with_index do |response, index|
      ElasticSearch::Response.new(relations[index], response)
    end
  end
end

