module SearchFlip
  # The SearchFlip::Result class basically is a hash wrapper that uses
  # Hashie::Mash to provide convenient method access to the hash attributes.

  class Result < Hashie::Mash
    def self.disable_warnings?(*args)
      true
    end
  end
end
