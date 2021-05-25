require "ruby2_keywords"
require "forwardable"
require "http"
require "hashie"
require "thread"
require "json"
require "oj"
require "set"

require "search_flip/version"
require "search_flip/null_instrumenter"
require "search_flip/helper"
require "search_flip/exceptions"
require "search_flip/json"
require "search_flip/http_client"
require "search_flip/config"
require "search_flip/connection"
require "search_flip/bulk"
require "search_flip/filterable"
require "search_flip/customable"
require "search_flip/explainable"
require "search_flip/highlightable"
require "search_flip/paginatable"
require "search_flip/sortable"
require "search_flip/sourceable"
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
      super

      @code = code
      @body = body
    end

    def to_s
      "#{self.class.name} (#{code}): #{body}"
    end
  end
end
