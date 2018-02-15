
require "forwardable"
require "http"
require "hashie"
require "set"

require "search_flip/version"
require "search_flip/http_client"
require "search_flip/config"
require "search_flip/bulk"
require "search_flip/filterable_relation"
require "search_flip/post_filterable_relation"
require "search_flip/aggregatable_relation"
require "search_flip/aggregation_relation"
require "search_flip/relation"
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
  # @param relations [Array<SearchFlip::Relation>] An array of search
  #   queries to execute in parallel
  #
  # @return [Array<SearchFlip::Response>] An array of responses

  def self.msearch(relations)
    payload = relations.flat_map do |relation|
      [JSON.generate(index: relation.target.index_name_with_prefix, type: relation.target.type_name), JSON.generate(relation.request)]
    end

    payload = payload.join("\n")
    payload << "\n"

    SearchFlip::HTTPClient.headers(accept: "application/json", content_type: "application/x-ndjson").post("#{SearchFlip::Config[:base_url]}/_msearch", body: payload).parse["responses"].map.with_index do |response, index|
      SearchFlip::Response.new(relations[index], response)
    end
  end
end

