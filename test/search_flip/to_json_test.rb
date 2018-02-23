
require File.expand_path("../../test_helper", __FILE__)
require "search_flip/to_json"

class SearchFlip::ToJsonTest < SearchFlip::TestCase
  def test_time
    Timecop.freeze Time.parse("2018-01-01 12:00:00 UTC") do
      assert_equal "\"2018-01-01T12:00:00.000000Z\"", Time.now.utc.to_json
    end
  end

  def test_date
    Timecop.freeze Time.parse("2018-01-01 12:00:00 UTC") do
      assert_equal "\"2018-01-01\"", Date.today.to_json
    end
  end

  def test_date_time
    Timecop.freeze Time.parse("2018-01-01 12:00:00 UTC") do
      assert_equal "\"2018-01-01T12:00:00.000000Z\"", Time.now.utc.to_json
    end
  end

  def test_time_with_zone
    Timecop.freeze Time.parse("2018-01-01 12:00:00 UTC") do
      assert_equal "\"2018-01-01T12:00:00.000000Z\"", Time.find_zone("UTC").now.to_json
    end
  end
end

