require File.expand_path("../spec_helper", __dir__)

RSpec.describe SearchFlip::JSON do
  describe ".generate" do
    it "encodes timestamps correctly" do
      Timecop.freeze "2020-06-01 12:00:00 UTC" do
        expect(described_class.generate(timestamp: Time.now.utc)).to eq('{"timestamp":"2020-06-01T12:00:00Z"}')
      end
    end

    it "delegates to Oj" do
      allow(Oj).to receive(:dump)

      payload = { key: "value" }

      described_class.generate(payload)

      expect(Oj).to have_received(:dump).with(payload, mode: :custom, time_format: :xmlschema, bigdecimal_as_decimal: false)
    end

    it "generates json" do
      expect(described_class.generate(key: "value")).to eq('{"key":"value"}')
    end
  end

  describe ".parse" do
    it "returns the parsed json payload" do
      expect(described_class.parse('{"key":"value"}')).to eq("key" => "value")
    end

    it "delegates to Oj" do
      allow(Oj).to receive(:load)

      payload = '{"key":"value"}'

      described_class.parse(payload)

      expect(Oj).to have_received(:load).with(payload, mode: :custom, time_format: :xmlschema, bigdecimal_as_decimal: false)
    end
  end
end
