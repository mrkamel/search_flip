module SearchFlip
  class JSON
    def self.generate(obj)
      Oj.dump(obj, mode: :custom, use_to_json: true)
    end

    def self.parse(str)
      Oj.load(str, mode: :custom, object_class: SearchFlip::JsonHash)
    end
  end
end
