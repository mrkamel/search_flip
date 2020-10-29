require File.expand_path("../spec_helper", __dir__)

RSpec.describe SearchFlip::JSON do
  describe ".generate" do
    it "delegates to Oj" do
      allow(Oj).to receive(:dump)

      payload = { key: "value" }

      described_class.generate(payload)

      expect(Oj).to have_received(:dump).with(payload, mode: :custom, use_to_json: true)
    end

    it "generates json" do
      expect(described_class.generate(key: "value")).to eq('{"key":"value"}')
    end
  end

  describe ".parse" do
    it "delegates to Oj" do
      allow(Oj).to receive(:load)

      payload = '{"key":"value"}'

      described_class.parse(payload)

      expect(Oj).to have_received(:load).with(payload)
    end
  end
end
