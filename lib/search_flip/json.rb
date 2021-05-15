module SearchFlip
  class JSON
    @default_options = {
      mode: :custom,
      time_format: :xmlschema
    }

    def self.default_options
      @default_options
    end

    def self.generate(obj)
      Oj.dump(obj, default_options)
    end

    def self.parse(json)
      Oj.load(json)
    end
  end
end
