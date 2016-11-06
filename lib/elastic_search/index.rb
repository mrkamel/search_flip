
module ElasticSearch
  module Index
    def self.included(base)
      base.extend ClassMethods

      base.class_attribute :default_scopes
      base.default_scopes = []

      base.class_attribute :index_scopes
      base.index_scopes = []

      base.class_attribute :scopes
      base.scopes = {}
    end

    module ClassMethods
      def index_options(object)
        {}
      end

      def serialize(object)
        {}
      end

      def default_scope(&block)
        self.default_scopes = default_scopes + [block]
      end

      def scope(name, &block)
        define_singleton_method name do |*args, &blk|
          relation.send(name, *args, &blk)
        end

        self.scopes = scopes.merge(name.to_s => block)
      end

      def index_scope(&block)
        if block_given?
          self.index_scopes = index_scopes + [block]
        else
          index_scope_for model
        end
      end

      def index_scope_for(scope)
        index_scopes.inject(scope) { |orig, cur| cur.call scope }
      end

      def get(object)
        docs = scope.collect { |object| { :_id => object.id }.merge(index_options(object).symbolize_keys.slice(:routing, :_routing)) }

        JSON.parse(RestClient.post("#{type_url}/_mget", JSON.generate(:docs => docs)))["docs"].collect { |doc| Hashy.new doc }
      end

      def relation
        default_scopes.inject(ElasticSearch::Relation.new(:target => self)) { |relation, scope| relation.instance_exec(&scope) }
      end

      [:profile, :where, :where_not, :filter, :range, :match_all, :exists, :exists_not, :post_where, :post_where_not, :post_filter, :post_range,
        :post_exists, :post_exists_not, :aggregate, :facet, :scroll, :source, :includes, :eager_load, :preload, :sort, :order, :offset, :limit,
        :paginate, :query, :search, :find_in_batches, :find_each, :failsafe, :total_entries].each do |method|
          define_method method do |*args, &block|
            relation.send(:"#{method}", *args, &block)
          end
      end

      def type_name
        name.pluralize.underscore
      end

      def index_name
        [ElasticSearch::Config[:index_prefix], type_name].join("-")
      end

      def index_settings
        {}
      end

      def create_index
        RestClient.put index_url, JSON.generate(index_settings)
      end

      def delete_index
        RestClient.delete index_url
      end

      def mapping
        {}
      end

      def update_mapping
        RestClient.put "#{type_url}/_mapping", JSON.generate(mapping)
      end

      def get_mapping
        JSON.parse RestClient.get("#{type_url}/_mapping")
      end

      def refresh
        RestClient.post "#{index_url}/_refresh", "{}"
      end

      def index(scope, options = {}, _index_options = {})
        bulk options do |indexer|
          (scope.respond_to?(:find_each) ? index_scope_for(scope).find_each : Array(scope)).each do |object|
            indexer.index object.id, JSON.generate(serialize(object)), index_options(object).merge(_index_options)
          end
        end

        scope
      end

      def import(*args)
        index(*args)
      end

      def create(scope, options = {}, _index_options = {})
        bulk options do |indexer|
          (scope.respond_to?(:find_each) ? index_scope_for(scope).find_each : Array(scope)).each do |object|
            indexer.create object.id, JSON.generate(serialize(object)), index_options(object).merge(_index_options)
          end
        end

        scope
      end

      def update(scope, options = {}, _index_options = {})
        bulk options do |indexer|
          (scope.respond_to?(:find_each) ? index_scope_for(scope).find_each : Array(scope)).each do |object|
            indexer.update object.id, JSON.generate(:doc => serialize(object)), index_options(object).merge(_index_options)
          end
        end

        scope
      end

      def delete(scope, options = {}, _index_options = {})
        bulk options do |indexer|
          (scope.respond_to?(:find_each) ? find_each : Array(scope)).each do |object|
            indexer.delete object.id, index_options(object).merge(_index_options)
          end
        end

        scope
      end

      def bulk(options = {})
        ElasticSearch::Bulk.new("#{type_url}/_bulk", ElasticSearch::Config[:bulk_limit], options) do |indexer|
          yield indexer
        end

        refresh if ElasticSearch::Config[:environment] == "test"
      end

      def type_url
        "#{index_url}/#{type_name}"
      end

      def index_url
        "#{base_url}/#{index_name}"
      end

      def base_url
        ElasticSearch::Config[:base_url]
      end
    end
  end
end

