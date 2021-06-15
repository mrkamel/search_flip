module SearchFlip
  # The SearchFlip::HTTPClient class wraps the http gem and responsible for the
  # http request/response handling, ie communicating with Elasticsearch. You
  # only need to use it directly if you need authentication to communicate with
  # Elasticsearch or if you want to set some custom http settings.
  #
  # @example
  #   http_client = SearchFlip::HTTPClient.new
  #
  #   # Basic Auth
  #   http_client = http_client.basic_auth(user: "username", pass: "password")
  #
  #   # Raw Auth Header
  #   http_client = http_client.auth("Bearer VGhlIEhUVFAgR2VtLCBST0NLUw")
  #
  #   # Proxy Settings
  #   http_client = http_client.via("proxy.host", 8080)
  #
  #   # Custom headers
  #   http_client = http_client.headers(key: "value")
  #
  #   # Timeouts
  #   http_client = http_client.timeout(20)
  #
  #   SearchFlip::Connection.new(base_url: "...", http_client: http_client)

  class HTTPClient
    attr_accessor :request, :plugins

    def initialize(plugins: [])
      self.request = HTTP
      self.plugins = plugins
    end

    class << self
      extend Forwardable

      def_delegators :new, :headers, :via, :basic_auth, :auth, :timeout
      def_delegators :new, :get, :post, :put, :delete, :head
    end

    [:headers, :via, :basic_auth, :auth, :timeout].each do |method|
      define_method method do |*args|
        dup.tap do |client|
          client.request = request.send(method, *args)
        end
      end

      ruby2_keywords method
    end

    [:get, :post, :put, :delete, :head].each do |method|
      define_method(method) do |uri, options = {}|
        execute(method, uri, options)
      end
    end

    private

    def execute(method, uri, options = {})
      final_request = plugins.inject(self) { |res, cur| cur.call(res, method, uri, options) }
      response = final_request.request.send(method, uri, options)

      raise SearchFlip::ResponseError.new(code: response.code, body: response.body.to_s) unless response.status.success?

      response
    rescue HTTP::ConnectionError => e
      raise SearchFlip::ConnectionError, e.message
    end
  end
end
