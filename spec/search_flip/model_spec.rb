require File.expand_path("../spec_helper", __dir__)

class TestProduct < Product
  include SearchFlip::Model

  notifies_index(ProductIndex)
end

RSpec.describe SearchFlip::Model do
  describe "#save" do
    it "imports the record to the index" do
      expect(ProductIndex.total_count).to eq(0)

      TestProduct.create!

      expect(ProductIndex.total_count).to eq(1)
    end
  end

  describe "#destroy" do
    it "delete the record from the index" do
      test_product = TestProduct.create!

      expect(ProductIndex.total_count).to eq(1)

      test_product.destroy

      expect(ProductIndex.total_count).to eq(0)
    end
  end

  describe "#touch" do
    it "imports the record to the index" do
      test_product = Timecop.freeze(Time.parse("2016-01-01 12:00:00")) { TestProduct.create! }

      updated_at = ProductIndex.match_all.results.first.updated_at

      Timecop.freeze(Time.parse("2017-01-01 12:00:00")) { test_product.touch }

      expect(ProductIndex.match_all.results.first.updated_at).not_to eq(updated_at)
    end
  end
end
