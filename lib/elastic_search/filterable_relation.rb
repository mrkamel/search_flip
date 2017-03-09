
module ElasticSearch
  # The ElasticSearch::FilterableRelation mixin provides elegant and chainable
  # methods like #where, #exists, #range, etc to add search filters to a
  # relation.
  #
  # @example
  #   CommentIndex.where(public: true)
  #   CommentIndex.exists(:user_id)
  #   CommentIndex.range(:created_at, gt: Date.today - 7)

  module FilterableRelation
    def self.included(base)
      base.class_eval do
        attr_accessor :filter_values
      end
    end

    # Adds filters to your relation for the supplied hash composed of
    # field-to-filter mappings which specify terms, term or range filters,
    # depending on the type of the respective hash value, namely array, range
    # or scalar type like Fixnum, String, etc.
    #
    # @example
    #   CommentIndex.where(id: [1, 2, 3], state: ["approved", "declined"])
    #   CommentIndex.where(id: 1 .. 100)
    #   CommentIndex.where(created_at: Time.parse("2016-01-01") .. Time.parse("2017-01-01"))
    #   CommentIndex.where(id: 1, message: "hello")
    #
    # @param hash [Hash] A field-to-filter mapping specifying filter values for
    #   the respective fields
    #
    # @return [ElasticSearch::Relation] A newly created extended relation

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
            { :not => { :range => { key => { :gte => value.min, :lte => value.max } } } }
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

