
require File.expand_path("../test_helper", __FILE__)

class IndexTest < ElasticSearch::TestCase
  def test_create_index
    assert TestIndex.create_index
    assert TestIndex.index_exists?

    TestIndex.delete_index

    refute TestIndex.index_exists?
  end

  def test_index_exists?
    # Already tested
  end

  def test_delete_index
    TestIndex.create_index

    assert TestIndex.index_exists?
    assert TestIndex.delete_index

    refute TestIndex.index_exists?
  end

  def test_update_mapping
    TestIndex.create_index
    TestIndex.update_mapping

    mapping = TestIndex.get_mapping

    assert mapping["test"]["mappings"]["test"]["properties"]["test_field"]

    TestIndex.delete_index
  end

  def test_get_mapping
    # Aready tested
  end
end

