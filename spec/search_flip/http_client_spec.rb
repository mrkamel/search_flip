
require File.expand_path("../spec_helper", __dir__)

RSpec.describe SearchFlip::HTTPClient do
  [:get, :put, :delete, :post, :head].each do |method|
    describe ".#{method}" do
      it "performs the specified request" do
        stub_request(method, "http://localhost/path").with(body: "body", query: { key: "value" }).to_return(body: "success")

        expect(SearchFlip::HTTPClient.send(method, "http://localhost/path", body: "body", params: { key: "value" }).body.to_s).to eq("success")
      end
    end
  end

  describe ".headers" do
    it "passes the specified headers" do
      stub_request(:get, "http://localhost/path").with(headers: { "X-Key" => "Value" }).to_return(body: "success")

      expect(SearchFlip::HTTPClient.headers("X-Key" => "Value").get("http://localhost/path").body.to_s).to eq("success")
    end
  end

  it "raises SearchFlip::ConnectionError" do
    stub_request(:get, "http://localhost/path").to_raise(HTTP::ConnectionError)

    expect { SearchFlip::HTTPClient.get("http://localhost/path") }.to raise_error(SearchFlip::ConnectionError)
  end

  it "raises SearchFlip::ResponseError" do
    stub_request(:get, "http://localhost/path").to_return(status: 500)

    expect { SearchFlip::HTTPClient.get("http://localhost/path") }.to raise_error(SearchFlip::ResponseError)
  end
end
