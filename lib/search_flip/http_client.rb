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
      opts = options.dup
      final_request = self

      if opts[:json]
        # Manually generate and pass the json body to http-rb to guarantee that
        # we have the same json which is used for aws signatures and to
        # guarantee that json is always generated as stated in the config

        opts[:body] = JSON.generate(opts.delete(:json))
        final_request = final_request.headers(content_type: "application/json")
      end

      final_request = plugins.inject(final_request) { |res, cur| cur.call(res, method, uri, opts) }
      final_request = final_request.headers({}) # Prevent thread-safety issue of http-rb: https://github.com/httprb/http/issues/558

      response = final_request.request.send(method, uri, opts)

      raise SearchFlip::ResponseError.new(code: response.code, body: response.body.to_s) unless response.status.success?

      response
    rescue HTTP::ConnectionError => e
      raise SearchFlip::ConnectionError, e.message
    rescue HTTP::TimeoutError => e
      raise SearchFlip::TimeoutError, e.message
    rescue HTTP::Error => e
      raise SearchFlip::HttpError, e.message
    end
  end
end
