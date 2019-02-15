
require File.expand_path("../test_helper", __dir__)

class SearchFlip::ConfigTest < SearchFlip::TestCase
  def test_version
    assert SearchFlip.version
    assert SearchFlip.version(base_url: SearchFlip::Config[:base_url])
  end
end

