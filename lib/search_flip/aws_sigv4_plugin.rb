require "aws-sdk-core"
require "uri"

module SearchFlip
  # The SearchFlip::AwsSigV4Plugin is a plugin for the SearchFlip::HTTPClient
  # to be used with AWS Elasticsearch to sign requests, i.e. add signed
  # headers, before sending the request to Elasticsearch.
  #
  # @example
  #   MyConnection = SearchFlip::Connection.new(
  #     base_url: "https://your-elasticsearch-cluster.es.amazonaws.com",
  #     http_client: SearchFlip::HTTPClient.new(
  #       plugins: [
  #         SearchFlip::AwsSigv4Plugin.new(
  #           region: "...",
  #           access_key_id: "...",
  #           secret_access_key: "..."
  #         )
  #       ]
  #     )
  #   )

  class AwsSigv4Plugin
    attr_accessor :signer

    def initialize(options = {})
      self.signer = Aws::Sigv4::Signer.new({ service: "es" }.merge(options))
    end

    def call(request, method, uri, options = {})
      full_uri = URI.parse(uri)
      full_uri.query = URI.encode_www_form(options[:params].to_a) if options[:params]

      signature_request = {
        http_method: method.to_s.upcase,
        url: full_uri.to_s
      }

      signature_request[:body] = options[:body] if options.key?(:body)
      signature_request[:body] = options[:json].respond_to?(:to_str) ? options[:json] : JSON.generate(options[:json]) if options[:json]

      signature = signer.sign_request(signature_request)

      request.headers(signature.headers)
    end
  end
end
