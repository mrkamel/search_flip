require File.expand_path("../spec_helper", __dir__)

RSpec.describe SearchFlip::Result do
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

    it "works with the _source being disabled" do
      result = SearchFlip::Result.from_hit("_id" => 1)

      expect(result._hit._id).to eq(1)
    end
  end
end
