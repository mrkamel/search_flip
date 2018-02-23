
require "time"
require "date"
require "json"

class Time
  def to_json
    iso8601(6).to_json
  end
end

class Date
  def to_json
    iso8601.to_json
  end
end

class DateTime
  def to_json
    iso8601(6).to_json
  end
end

