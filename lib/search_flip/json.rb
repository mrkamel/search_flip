module SearchFlip
  class JSON
    def self.generate(obj)
      Oj.dump(obj, SearchFlip::Config[:json_options])
    end

    def self.parse(json)
      Oj.load(json, SearchFlip::Config[:json_options])
    end
  end
end
