require "aws-sdk-core"
require "uri"

module SearchFlip
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
