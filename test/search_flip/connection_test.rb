
require File.expand_path("../test_helper", __dir__)

class SearchFlip::ConnectionTest < SearchFlip::TestCase
  def test_base_url
    assert_equal SearchFlip::Connection.new(base_url: "base url").base_url, "base url"
  end

  def test_msearch
    ProductIndex.import create(:product)
    CommentIndex.import create(:comment)

    responses = SearchFlip::Connection.new.msearch([ProductIndex.match_all, CommentIndex.match_all])

    assert_equal 2, responses.size
    assert_equal 1, responses[0].total_entries
    assert_equal 1, responses[1].total_entries
  end

  def test_update_aliases
    connection = SearchFlip::Connection.new

    assert connection.update_aliases(actions: [add: { index: "products", alias: "alias1" }])
    assert connection.update_aliases(actions: [remove: { index: "products", alias: "alias1" }])
  end

  def test_get_index_aliases
    connection = SearchFlip::Connection.new

    connection.update_aliases(actions: [
      { add: { index: "comments", alias: "alias1" } },
      { add: { index: "products", alias: "alias2" } },
      { add: { index: "products", alias: "alias3" } }
    ])

    assert_equal connection.get_aliases.keys.sort, ["comments", "products"].sort
    assert_equal connection.get_aliases["products"]["aliases"].keys, ["alias2", "alias3"]
    assert_equal connection.get_aliases["comments"]["aliases"].keys, ["alias1"]
    assert_equal connection.get_aliases(index_name: "products").keys, ["products"]
    assert_equal connection.get_aliases(index_name: "comments,products").keys.sort, ["comments", "products"]
    assert_equal connection.get_aliases(alias_name: "alias1,alias2").keys.sort, ["comments", "products"]
    assert_equal connection.get_aliases(alias_name: "alias1,alias2")["products"]["aliases"].keys, ["alias2"]
  ensure
    connection.update_aliases(actions: [
      { remove: { index: "comments", alias: "alias1" } },
      { remove: { index: "products", alias: "alias2" } },
      { remove: { index: "products", alias: "alias3" } }
    ])
  end

  def test_alias_exists?
    connection = SearchFlip::Connection.new

    refute connection.alias_exists?(:some_alias)

    connection.update_aliases(actions: [add: { index: "products", alias: "some_alias" }])

    assert connection.alias_exists?(:some_alias)
  ensure
    connection.update_aliases(actions: [remove: { index: "products", alias: "some_alias" }])
  end
end

