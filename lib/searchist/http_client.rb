
module Searchist
  # @api private
  #
  # The Searchist::HTTPClient class wraps the http gem, is for internal use
  # and responsible for the http request/response handling, ie communicating
  # with ElasticSearch.

  class HTTPClient
    class Request
      attr_accessor :headers_hash

      def headers(hash = {})
        dup.tap do |request|
          request.headers_hash = (request.headers_hash || {}).merge(hash)
        end
      end

      [:get, :post, :put, :delete].each do |method|
        define_method method do |*args|
          execute(method, *args)
        end
      end

      private

      def execute(method, *args)
        response = HTTP.headers(headers_hash || {}).send(method, *args)

        raise Searchist::ResponseError.new(code: response.code, body: response.body.to_s) unless response.status.success?

        response
      rescue HTTP::ConnectionError => e
        raise Searchist::ConnectionError, e.message
      end
    end

    def self.request
      Request.new
    end

    class << self
      extend Forwardable

      def_delegators :request, :headers, :get, :post, :put, :delete
    end
  end
end

