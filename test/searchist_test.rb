
require File.expand_path("../test_helper", __FILE__)

class SearchistTest < Searchist::TestCase
  def test_msearch
    ProductIndex.import create(:product)
    CommentIndex.import create(:comment)

    responses = Searchist.msearch([ProductIndex.match_all, CommentIndex.match_all])

    assert_equal 2, responses.size
    assert_equal 1, responses[0].total_entries
    assert_equal 1, responses[1].total_entries
  end
end

