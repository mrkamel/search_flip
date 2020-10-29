require File.expand_path("../spec_helper", __dir__)

RSpec.describe SearchFlip::Result do
  describe ".convert" do
    it "deeply converts hashes and arrays" do
      result = described_class.convert("parent" => { "child" => [{ "key1" => "value" }, { "key2" => 3 }] })

      expect(result.parent.child[0].key1).to eq("value")
      expect(result.parent.child[1].key2).to eq(3)
    end
  end

  describe "#method_missing" do
    it "returns the value of the key equal to the message name" do
      expect(described_class.convert("some_key" => "value").some_key).to eq("value")
      expect(described_class.new.some_key).to be_nil
    end
  end

  describe "#responds_to_missing?" do
    it "returns true/false if the key equal to the message name is present or not" do
      expect(described_class.convert("some_key" => nil).respond_to?(:some_key)).to eq(true)
      expect(described_class.convert("some_key" => nil).respond_to?(:other_key)).to eq(false)
    end
  end

  describe ".from_hit" do
    it "adds a _hit key into _source and merges the hit keys into it" do
      result = SearchFlip::Result.from_hit("_score" => 1.0, "_source" => { "name" => "Some name" })

      expect(result).to eq("name" => "Some name", "_hit" => { "_score" => 1.0 })
    end

    it "works with the _source being disabled" do
      result = SearchFlip::Result.from_hit("_id" => 1)

      expect(result._hit._id).to eq(1)
    end
  end
end
