
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

  def test_get_indices
    connection = SearchFlip::Connection.new

    assert_equal connection.get_indices.map { |index| index["index"] }.sort, ["comments", "products"]
    assert_equal connection.get_indices("com*").map { |index| index["index"] }.sort, ["comments"]
  end

  def test_create_index
    connection = SearchFlip::Connection.new

    assert connection.create_index("index_name")
    assert connection.index_exists?("index_name")
  ensure
    connection.delete_index("index_name") if connection.index_exists?("index_name")
  end

  def test_create_index_with_index_payload
    connection = SearchFlip::Connection.new

    connection.create_index("index_name", settings: { number_of_shards: 3 })

    assert_equal connection.get_index_settings("index_name")["index_name"]["settings"]["index"]["number_of_shards"], "3"
  ensure
    connection.delete_index("index_name") if connection.index_exists?("index_name")
  end

  def test_update_index_settings
    connection = SearchFlip::Connection.new

    connection.create_index("index_name")
    connection.update_index_settings("index_name", settings: { number_of_replicas: 3 })

    assert_equal "3", connection.get_index_settings("index_name")["index_name"]["settings"]["index"]["number_of_replicas"]
  ensure
    connection.delete_index("index_name") if connection.index_exists?("index_name")
  end

  def test_get_index_settings
    connection = SearchFlip::Connection.new

    connection.create_index("index_name", settings: { number_of_shards: 3 })

    assert_equal connection.get_index_settings("index_name")["index_name"]["settings"]["index"]["number_of_shards"], "3"
  ensure
    connection.delete_index("index_name") if connection.index_exists?("index_name")
  end

  def test_update_mapping
    connection = SearchFlip::Connection.new

    mapping = { "type_name" => { "properties" => { "id" => { "type" => "long" } } } }

    connection.create_index("index_name")
    connection.update_mapping("index_name", "type_name", mapping)

    assert_equal connection.get_mapping("index_name", "type_name"), "index_name" => { "mappings" => mapping }
  ensure
    connection.delete_index("index_name") if connection.index_exists?("index_name")
  end

  def test_delete_index
    connection = SearchFlip::Connection.new

    connection.create_index("index_name")
    assert connection.index_exists?("index_name")

    connection.delete_index("index_name")
    refute connection.index_exists?("index_name")
  ensure
    connection.delete_index("index_name") if connection.index_exists?("index_name")
  end

  def test_refresh
    connection = SearchFlip::Connection.new

    connection.create_index("index1")
    connection.create_index("index2")

    assert connection.refresh
    assert connection.refresh("index1")
    assert connection.refresh(["index1", "index2"])
  ensure
    connection.delete_index("index1") if connection.index_exists?("index1")
    connection.delete_index("index2") if connection.index_exists?("index2")
  end

  def test_index_url
    connection = SearchFlip::Connection.new(base_url: "base_url")

    assert_equal "base_url/index_name", connection.index_url("index_name")
  end

  def test_type_url
    connection = SearchFlip::Connection.new(base_url: "base_url")

    assert_equal "base_url/index_name/type_name", connection.type_url("index_name", "type_name")
  end
end

