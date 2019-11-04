require "time"
require "date"
require "json"

class Time
  def to_json(*args)
    iso8601(6).to_json
  end
end

class Date
  def to_json(*args)
    iso8601.to_json
  end
end

class DateTime
  def to_json(*args)
    iso8601(6).to_json
  end
end

if defined?(ActiveSupport)
  class ActiveSupport::TimeWithZone
    def to_json(*args)
      iso8601(6).to_json
    end
  end
end
