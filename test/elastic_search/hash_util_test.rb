
require File.expand_path("../../test_helper", __FILE__)

class ElasticSearch::HashUtilTest < ElasticSearch::TestCase
  def test_except
    assert_equal({ key1: "value1", key2: "value2" }, ElasticSearch::HashUtil.new(key1: "value1", key2: "value2", key3: "value3", key4: "value4").except(:key3, :key4))
  end
end

