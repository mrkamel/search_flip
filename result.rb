
require "hashr"

module ElasticSearch
  class Result < Hashr
    def to_param
      id.to_param
    end
  end
end

