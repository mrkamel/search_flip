
require File.expand_path("../spec_helper", __dir__)
require "search_flip/to_json"

RSpec.describe do
  it "uses the correct format for Time" do
    Timecop.freeze Time.parse("2018-01-01 12:00:00 UTC") do
      expect(Time.now.utc.to_json).to eq("\"2018-01-01T12:00:00.000000Z\"")
    end
  end

  it "uses the correct format for Date" do
    Timecop.freeze Time.parse("2018-01-01 12:00:00 UTC") do
      expect(Date.today.to_json).to eq("\"2018-01-01\"")
    end
  end

  it "uses the correct format for DateTime" do
    Timecop.freeze Time.parse("2018-01-01 12:00:00 UTC") do
      expect(Time.now.utc.to_json).to eq("\"2018-01-01T12:00:00.000000Z\"")
    end
  end

  it "uses the correct format for TimeWithZone" do
    Timecop.freeze Time.parse("2018-01-01 12:00:00 UTC") do
      expect(Time.find_zone("UTC").now.to_json).to eq("\"2018-01-01T12:00:00.000000Z\"")
    end
  end
end
