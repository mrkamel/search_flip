
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

  def test_refresh
    ProductIndex.import create(:product)

    assert ProductIndex.refresh
  end

  def test_delegation
    relation = mock

    ProductIndex.stubs(:relation).returns(relation)

    relation.expects(:profile)
    ProductIndex.profile(true)

    relation.expects(:where)
    ProductIndex.where(:key => "value")

    relation.expects(:where_not)
    ProductIndex.where_not(:field => "value")

    relation.expects(:filter)
    ProductIndex.filter(:terms => { :field => "value" })

    relation.expects(:range)
    ProductIndex.range(:field, :gt => 0, :lt => 2)

    relation.expects(:match_all)
    ProductIndex.match_all

    relation.expects(:exists)
    ProductIndex.exists(:field)

    relation.expects(:exists_not)
    ProductIndex.exists_not(:field)

    relation.expects(:post_where)
    ProductIndex.post_where(:field => "value")

    relation.expects(:post_where_not)
    ProductIndex.post_where_not(:field => "value")

    relation.expects(:post_filter)
    ProductIndex.post_filter(:terms => { :field => "value" })

    relation.expects(:post_range)
    ProductIndex.post_range(:field, :gt => 0, :lt => 2)

    relation.expects(:post_exists)
    ProductIndex.post_exists(:field)

    relation.expects(:post_exists_not)
    ProductIndex.post_exists_not(:field)

    relation.expects(:aggregate)
    ProductIndex.aggregate(:field)

    relation.expects(:facet)
    ProductIndex.facet(:field)

    relation.expects(:scroll)
    ProductIndex.scroll

    relation.expects(:source)
    ProductIndex.source([:field1, :field2])

    relation.expects(:includes)
    ProductIndex.includes(:association)

    relation.expects(:eager_load)
    ProductIndex.eager_load(:assocation)

    relation.expects(:preload)
    ProductIndex.preload(:assocation)

    relation.expects(:sort)
    ProductIndex.sort(:field)

    relation.expects(:order)
    ProductIndex.order(:field)

    relation.expects(:offset)
    ProductIndex.offset(30)

    relation.expects(:limit)
    ProductIndex.limit(30)

    relation.expects(:paginate)
    ProductIndex.paginate(:page => 1)

    relation.expects(:query)
    ProductIndex.query("query")

    relation.expects(:search)
    ProductIndex.search("query")

    relation.expects(:find_in_batches)
    ProductIndex.find_in_batches

    relation.expects(:find_each)
    ProductIndex.find_each

    relation.expects(:failsafe)
    ProductIndex.failsafe(true)

    relation.expects(:total_entries)
    ProductIndex.total_entries
  end
end

