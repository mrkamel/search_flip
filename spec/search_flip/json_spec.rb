require File.expand_path("../spec_helper", __dir__)

RSpec.describe SearchFlip::JSON do
  describe ".generate" do
    it "encodes timestamps correctly" do
      Timecop.freeze "2020-06-01 12:00:00 UTC" do
        expect(described_class.generate(timestamp: Time.now.utc)).to eq('{"timestamp":"2020-06-01T12:00:00.000Z"}')
      end
    end

    it "encodes bigdecimals as string" do
      expect(described_class.generate(value: BigDecimal(1))).to eq('{"value":"1.0"}')
    end

    it "delegates to Oj" do
      allow(Oj).to receive(:dump)

      payload = { key: "value" }

      described_class.generate(payload)

      expect(Oj).to have_received(:dump).with(payload, mode: :custom, use_to_json: true, time_format: :xmlschema, bigdecimal_as_decimal: false)
    end

    it "generates json" do
      expect(described_class.generate(key: "value")).to eq('{"key":"value"}')
    end
  end

  describe ".parse" do
    it "returns the parsed json payload" do
      expect(described_class.parse('{"key":"value"}')).to eq("key" => "value")
    end

    it "delegates to JSON" do
      allow(JSON).to receive(:parse)

      payload = '{"key":"value"}'

      described_class.parse(payload)

      expect(JSON).to have_received(:parse).with(payload)
    end
  end
end
