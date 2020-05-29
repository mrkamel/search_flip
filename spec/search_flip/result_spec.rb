require File.expand_path("../spec_helper", __dir__)

RSpec.describe SearchFlip::Result do
  describe ".from_hit" do
    it "adds a _hit key into _source and merges the hit keys into it" do
      result = SearchFlip::Result.from_hit("_score" => 1.0, "_source" => { "name" => "Some name" })

      expect(result).to eq("name" => "Some name", "_hit" => { "_score" => 1.0 })
    end

    it "allows deep method access" do
      result = SearchFlip::Result.from_hit("_source" => { "key1" => [{ "key2" => "value" }] })

      expect(result.key1[0].key2).to eq("value")
    end
  end
end
