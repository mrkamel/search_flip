
require "forwardable"
require "http"
require "hashie"
require "set"

require "searchist/version"
require "searchist/http_client"
require "searchist/config"
require "searchist/bulk"
require "searchist/filterable_relation"
require "searchist/post_filterable_relation"
require "searchist/aggregatable_relation"
require "searchist/aggregation_relation"
require "searchist/relation"
require "searchist/response"
require "searchist/result"
require "searchist/index"
require "searchist/model"

module Searchist
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
  # within a single request. Raises Searchist::ResponseError in case any
  # errors occur.
  #
  # @example
  #   Searchist.msearch [ProductIndex.match_all, CommentIndex.match_all]
  #
  # @param relations [Array<Searchist::Relation>] An array of search
  #   queries to execute in parallel
  #
  # @return [Array<Searchist::Response>] An array of responses

  def self.msearch(relations)
    payload = relations.flat_map do |relation|
      [JSON.generate(index: relation.target.index_name_with_prefix, type: relation.target.type_name), JSON.generate(relation.request)]
    end

    payload = payload.join("\n")
    payload << "\n"

    Searchist::HTTPClient.headers(accept: "application/json", content_type: "application/x-ndjson").post("#{Searchist::Config[:base_url]}/_msearch", body: payload).parse["responses"].map.with_index do |response, index|
      Searchist::Response.new(relations[index], response)
    end
  end
end

