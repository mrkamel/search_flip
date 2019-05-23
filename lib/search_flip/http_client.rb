
module SearchFlip
  # @api private
  #
  # The SearchFlip::HTTPClient class wraps the http gem, is for internal use
  # and responsible for the http request/response handling, ie communicating
  # with Elasticsearch.

  class HTTPClient
    attr_accessor :request

    def initialize
      self.request = HTTP
    end

    class << self
      extend Forwardable

      def_delegators :new, :headers, :via, :basic_auth, :auth
      def_delegators :new, :get, :post, :put, :delete, :head
    end

    [:headers, :via, :basic_auth, :auth].each do |method|
      define_method method do |*args|
        dup.tap do |client|
          client.request = request.send(method, *args)
        end
      end
    end

    [:get, :post, :put, :delete, :head].each do |method|
      define_method method do |*args|
        execute(method, *args)
      end
    end

    private

    def execute(method, *args)
      response = request.send(method, *args)

      raise SearchFlip::ResponseError.new(code: response.code, body: response.body.to_s) unless response.status.success?

      response
    rescue HTTP::ConnectionError => e
      raise SearchFlip::ConnectionError, e.message
    end
  end
end

