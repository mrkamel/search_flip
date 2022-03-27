require File.expand_path("../spec_helper", __dir__)
require "search_flip/aws_sigv4_plugin"

RSpec.describe SearchFlip::AwsSigv4Plugin do
  describe "#call" do
    subject(:plugin) do
      SearchFlip::AwsSigv4Plugin.new(
        region: "us-east-1",
        access_key_id: "access key",
        secret_access_key: "secret access key"
      )
    end

    let(:client) { SearchFlip::HTTPClient.new }

    it "adds the signed headers to the request" do
      Timecop.freeze Time.parse("2020-01-01 12:00:00 UTC") do
        expect(client).to receive(:headers).with(
          an_object_matching(
            "host" => "localhost",
            "authorization" => /.*/,
            "x-amz-content-sha256" => /.*/,
            "x-amz-date" => /20200101T120000Z/
          )
        )

        plugin.call(client, :get, "http://localhost/index")
      end
    end

    it "feeds the http method, full url and body to the signer" do
      signing_request = {
        http_method: "GET",
        url: "http://localhost/index?param=value",
        body: JSON.generate(key: "value")
      }

      expect(plugin.signer).to receive(:sign_request).with(signing_request).and_call_original

      plugin.call(client, :get, "http://localhost/index", params: { param: "value" }, json: { key: "value" })
    end
  end
end
