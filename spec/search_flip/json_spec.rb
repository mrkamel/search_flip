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

      expect(Oj).to have_received(:load).with(payload, mode: :custom, object_class: SearchFlip::JsonHash)
    end

    it "uses SearchFlip::JsonHash as object class" do
      expect(described_class.parse(JSON.dump(key: "value")).class).to be(SearchFlip::JsonHash)
    end

    it "allowed deep method access" do
      json = JSON.dump(parent: [{ child1: "value1" }, { child2: "value2" }])

      expect(described_class.parse(json).parent[0].child1).to eq("value1")
    end
  end
end
