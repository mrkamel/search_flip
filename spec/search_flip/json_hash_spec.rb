require File.expand_path("../spec_helper", __dir__)

RSpec.describe SearchFlip::JsonHash do
  describe "#method_missing" do
    it "returns the value of the key equal to the message name" do
      expect(described_class["some_key" => "value"].some_key).to eq("value")
      expect(described_class.new.some_key).to be_nil
    end
  end

  describe "#responds_to_missing?" do
    it "returns true/false if the key equal to the message name is present or not" do
      expect(described_class["some_key" => nil].respond_to?(:some_key)).to eq(true)
      expect(described_class["some_key" => nil].respond_to?(:other_key)).to eq(false)
    end
  end

  describe ".parse" do
    it "uses SearchFlip::JsonHash as object class" do
      expect(described_class.parse(JSON.dump(key: 'value')).class).to be(described_class)
    end

    it "allowed deep method access" do
      json = JSON.dump(parent: [{ child1: "value1" }, { child2: "value2" }])

      expect(described_class.parse(json).parent[0].child1).to eq("value1")
    end
  end
end
