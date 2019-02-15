
require File.expand_path("test_helper", __dir__)

class SearchFlipTest < SearchFlip::TestCase
  def test_msearch
    ProductIndex.import create(:product)
    CommentIndex.import create(:comment)

    responses = SearchFlip.msearch([ProductIndex.match_all, CommentIndex.match_all])

    assert_equal 2, responses.size
    assert_equal 1, responses[0].total_entries
    assert_equal 1, responses[1].total_entries

    assert SearchFlip.msearch([ProductIndex.match_all], base_url: ProductIndex.base_url)
  end

  def test_update_aliases
    assert SearchFlip.update_aliases(actions: [add: { index: "products", alias: "alias1" }])
    assert SearchFlip.update_aliases(actions: [remove: { index: "products", alias: "alias1" }])
  end

  def test_aliases
    SearchFlip.expects(:aliases).with("args").returns("delegated")

    assert_equal "delegated", SearchFlip.aliases("args")
  end

  def test_get_index_aliases
    SearchFlip.update_aliases(actions: [
      { add: { index: "comments", alias: "alias1" } },
      { add: { index: "products", alias: "alias2" } },
      { add: { index: "products", alias: "alias3" } }
    ])

    assert_equal SearchFlip.get_aliases.keys.sort, ["comments", "products"].sort
    assert_equal SearchFlip.get_aliases["products"]["aliases"].keys, ["alias2", "alias3"]
    assert_equal SearchFlip.get_aliases["comments"]["aliases"].keys, ["alias1"]
    assert_equal SearchFlip.get_aliases(index_name: "products").keys, ["products"]
    assert_equal SearchFlip.get_aliases(index_name: "comments,products").keys.sort, ["comments", "products"]
    assert_equal SearchFlip.get_aliases(alias_name: "alias1,alias2").keys.sort, ["comments", "products"]
    assert_equal SearchFlip.get_aliases(alias_name: "alias1,alias2")["products"]["aliases"].keys, ["alias2"]

    assert SearchFlip.get_aliases(alias_name: "alias1", base_url: SearchFlip::Config[:base_url])
  ensure
    SearchFlip.update_aliases(actions: [
      { remove: { index: "comments", alias: "alias1" } },
      { remove: { index: "products", alias: "alias2" } },
      { remove: { index: "products", alias: "alias3" } }
    ])
  end

  def test_alias_exists?
    refute SearchFlip.alias_exists?(:some_alias)

    SearchFlip.update_aliases(actions: [add: { index: "products", alias: "some_alias" }])

    assert SearchFlip.alias_exists?(:some_alias)
    assert SearchFlip.alias_exists?(:some_alias, base_url: SearchFlip::Config[:base_url])
  ensure
    SearchFlip.update_aliases(actions: [remove: { index: "products", alias: "some_alias" }])
  end
end

