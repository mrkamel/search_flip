require File.expand_path("../spec_helper", __dir__)

RSpec.describe SearchFlip::JSON do
  describe ".generate" do
    it "encodes timestamps correctly" do
      Timecop.freeze "2020-06-01 12:00:00 UTC" do
        expect(described_class.generate(timestamp: Time.now.utc)).to eq('{"timestamp":"2020-06-01T12:00:00.000Z"}')
      end
    end
  end

  describe ".parse" do
    it "returns the parsed json payload" do
      expect(described_class.parse('{"key":"value"}')).to eq("key" => "value")
    end
  end
end
