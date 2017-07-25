
module ElasticSearch
  # @api private
  #
  # The ElasticSearch::HTTPClient class wraps the http gem, is for internal use
  # and responsible for the http request/response handling, ie communication
  # with ElasticSearch Server.

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

        raise ElasticSearch::ResponseError.new(code: response.code, body: response.body.to_s) unless response.status.success?

        response
      rescue HTTP::ConnectionError => e
        raise ElasticSearch::ConnectionError, e.message
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

