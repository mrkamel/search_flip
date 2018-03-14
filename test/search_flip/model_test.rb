
require File.expand_path("../../test_helper", __FILE__)

class SearchFlip::ModelTest < SearchFlip::TestCase
  class TestProduct < Product
    include SearchFlip::Model

    notifies_index(ProductIndex)
  end

  def test_save
    assert_equal 0, ProductIndex.total_count

    TestProduct.create!

    assert_equal 1, ProductIndex.total_count
  end

  def test_destroy
    test_product = TestProduct.create!

    assert_equal 1, ProductIndex.total_count

    test_product.destroy

    assert_equal 0, ProductIndex.total_count
  end

  def test_touch
    test_product = Timecop.freeze(Time.parse("2016-01-01 12:00:00")) { TestProduct.create! }

    updated_at = ProductIndex.match_all.results.first.updated_at

    Timecop.freeze(Time.parse("2017-01-01 12:00:00")) { test_product.touch }

    refute_equal updated_at, ProductIndex.match_all.results.first.updated_at
  end
end

