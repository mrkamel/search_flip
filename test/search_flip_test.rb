
require File.expand_path("test_helper", __dir__)

class SearchFlipTest < SearchFlip::TestCase
  def test_msearch
    ProductIndex.import create(:product)
    CommentIndex.import create(:comment)

    responses = SearchFlip.msearch([ProductIndex.match_all, CommentIndex.match_all])

    assert_equal 2, responses.size
    assert_equal 1, responses[0].total_entries
    assert_equal 1, responses[1].total_entries
  end

  def test_aliases
    assert SearchFlip.aliases(actions: [add: { index: "products", alias: "alias1" }])
    assert SearchFlip.aliases(actions: [remove: { index: "products", alias: "alias1" }])
  end
end

