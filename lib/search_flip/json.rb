
module SearchFlip
  module JSON
    def self.generate(obj)
      Oj.dump(obj, mode: :custom, use_to_json: true)
    end
  end
end

