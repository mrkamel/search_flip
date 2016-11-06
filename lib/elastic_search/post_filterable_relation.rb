
module ElasticSearch
  module PostFilterableRelation
    def self.included(base)
      base.class_eval do
        attr_accessor :post_filter_values
      end
    end

    def post_where!(hash)
      clear_cache!

      self.post_filter_values = (post_filter_values || []) + hash.collect do |key, value|
        if value.is_a?(Array)
          { :terms => { key => value } }
        elsif value.is_a?(Range)
          { :range => { key => { :gte => value.min, :lte => value.max } } }
        else
          { :term => { key => value } }
        end
      end

      self
    end

    def post_where(hash)
      dup.tap do |relation|
        relation.post_where! hash
      end
    end

    def post_where_not!(hash)
      clear_cache!

      self.post_filter_values = (post_filter_values || []) + hash.collect do |key, value|
        if value.is_a?(Array)
          { :not => { :terms => { key => value } } }
        elsif value.is_a?(Range)
          { :not => { :range => { key => { :gte => value.min, :lt => value.max } } } }
        else
          { :not => { :term => { key => value } } }
        end
      end

      self
    end

    def post_where_not(hash)
      dup.tap do |relation|
        relation.post_where_not! hash
      end
    end

    def post_filter!(*args)
      clear_cache!

      self.post_filter_values = (post_filter_values || []) + args
      self
    end

    def post_filter(*args)
      dup.tap do |relation|
        relation.post_filter!(*args)
      end
    end

    def post_range!(field, options = {})
      post_filter! :range => { field => options }
    end

    def post_range(field, options = {})
      post_filter :range => { field => options }
    end

    def post_exists!(field)
      post_filter! :exists => { :field => field }
    end

    def post_exists(field)
      post_filter :exists => { :field => field }
    end

    def post_exists_not!(field)
      post_filter! :bool => { :must_not => { :exists => { :field => field }}}
    end

    def post_exists_not(field)
      post_filter :bool => { :must_not => { :exists => { :field => field }}}
    end
  end
end

