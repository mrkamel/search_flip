
module ElasticSearch
  module FilterableRelation
    def self.included(base)
      base.class_eval do
        attr_accessor :filter_values
      end
    end

    def where(hash)
      fresh.tap do |relation|
        relation.filter_values = (filter_values || []) + hash.collect do |key, value|
          if value.is_a?(Array)
            { :terms => { key => value } }
          elsif value.is_a?(Range)
            { :range => { key => { :gte => value.min, :lte => value.max } } }
          else
            { :term => { key => value } }
          end
        end
      end
    end

    def where_not(hash)
      fresh.tap do |relation|
        relation.filter_values = (filter_values || []) + hash.collect do |key, value|
          if value.is_a?(Array)
            { :not => { :terms => { key => value } } }
          elsif value.is_a?(Range)
            { :not => { :range => { key => { :gte => value.min, :lt => value.max } } } }
          else
            { :not => { :term => { key => value } } }
          end
        end
      end
    end

    def filter(*args)
      fresh.tap do |relation|
        relation.filter_values = (filter_values || []) + args
      end
    end

    def range(field, options = {})
      filter :range => { field => options }
    end

    def match_all
      filter :match_all => {}
    end

    def exists(field)
      filter :exists => { :field => field }
    end

    def exists_not(field)
      filter :bool => { :must_not => { :exists => { :field => field }}}
    end
  end
end

