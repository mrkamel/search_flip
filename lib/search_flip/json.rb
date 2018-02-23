
module SearchFlip
  class JSON
    @default_options = {
      mode: :custom,
      use_to_json: true
    }

    def self.default_options
      @default_options
    end

    def self.generate(obj)
      Oj.dump(obj, default_options)
    end
  end
end

