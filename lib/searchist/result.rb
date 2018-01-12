
module Searchist
  # The Searchist::Result class basically is a hash wrapper that uses
  # Hashie::Mash to provide convenient method access to the hash attributes.

  class Result < Hashie::Mash
    def self.disable_warnings?
      true
    end
  end
end

