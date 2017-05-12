
module ElasticSearch
  # The ElasticSearch::Index mixin makes your class correspond to an
  # ElasticSearch index. Your class can then create or delete the index, modify
  # the mapping, import records, delete records and query the index. This gem
  # uses an individual ElasticSearch index for each index class, because
  # ElasticSearch requires to have the same mapping for the same field name,
  # even if the field is living in different types of the same index.
  #
  # @example Simple index class
  #   class CommentIndex
  #     include ElasticSearch::Index
  #
  #     def self.model
  #       Comment
  #     end
  #
  #     def self.type_name
  #       "comments"
  #     end
  #
  #     def self.serialize(comment)
  #       {
  #         id: comment.id,
  #         user_id: comment.user_id,
  #         message: comment.message,
  #         created_at: comment.created_at
  #       }
  #     end
  #   end
  #
  # @example Create/delete the index
  #   CommentIndex.create_index
  #   CommentIndex.delete_index if CommentIndex.index_exists?
  #
  # @example Import records
  #   CommentIndex.import(Comment.all)
  #
  # @example Query the index
  #   CommentIndex.search("hello world")
  #   CommentIndex.where(user_id: 1)
  #   CommentIndex.range(:created_at, gt: Time.now - 7.days)

  module Index
    def self.included(base)
      base.extend ClassMethods

      base.class_attribute :index_scopes
      base.index_scopes = []

      base.class_attribute :scopes
      base.scopes = {}
    end

    module ClassMethods
      # Override this method to automatically pass index options for a record
      # at index-time, like routing or versioning.
      #
      # @example
      #   def self.index_options(comment)
      #     {
      #       routing: comment.user_id,
      #       version: comment.version,
      #       version_type: "external_gte"
      #     }
      #   end
      #
      # @param record The record that gets indexed
      # @return [Hash] The index options

      def index_options(record)
        {}
      end

      # @abstract
      #
      # Override this method to generate a hash representation of a record,
      # used to generate the JSON representation of it.
      #
      # @example
      #   def self.serialize(comment)
      #     {
      #       id: comment.id,
      #       user_id: comment.user_id,
      #       message: comment.message,
      #       created_at: comment.created_at,
      #       updated_at: comment.updated_at
      #     }
      #   end
      #
      # @param record The record that gets serialized
      # @return [Hash] The hash-representation of the record

      def serialize(record)
        raise NotImplementedError
      end

      # Adds a named scope to the index.
      #
      # @example
      #   scope(:active) { where(active: true) }
      #
      #   UserIndex.active
      #
      # @example
      #   scope(:active) { |value| where(active: value) }
      #
      #   UserIndex.active(true)
      #   UserIndex.active(false)
      #
      # @param name [Symbol] The name of the scope
      # @param block The scope definition. Add filters, etc.

      def scope(name, &block)
        define_singleton_method name do |*args, &blk|
          relation.send(name, *args, &blk)
        end

        self.scopes = scopes.merge(name.to_s => block)
      end

      # @api private
      #
      # Used to iterate a record set. Here, a record set may be a) an
      # ActiveRecord::Relation or anything responding to #find_each, b) an
      # Array of records or anything responding to #each or c) a single record.
      #
      # @param scope The record set that gets iterated
      # @param index_scope [Boolean] Set to true if you want the the index
      #   scopes to be applied to the scope

      def each_record(scope, index_scope: false)
        return enum_for(:each_record, scope) unless block_given?

        if scope.respond_to?(:find_each)
          (index_scope ? index_scope_for(scope) : scope).find_each do |record|
            yield record
          end
        else
          (scope.respond_to?(:each) ? scope : Array(scope)).each do |record|
            yield record
          end
        end
      end

      # Returns the record's id, ie the unique identifier or primary key of a
      # record. Override this method for custom primary keys, but return a
      # String or Fixnum.
      #
      # @example Default implementation
      #   def self.record_id(record)
      #     record.id
      #   end
      #
      # @example Custom primary key
      #   def self.record_id(user)
      #     user.username
      #   end
      #
      # @param record The record to get the primary key for
      # @return [String, Fixnum] The record's primary key

      def record_id(record)
        record.id
      end

      # Returns a record set, usually an ActiveRecord::Relation, for the
      # specified ids, ie primary keys. Override this method for custom primary
      # keys and/or ORMs.
      #
      # @param ids [Array] The array of ids to fetch the records for
      # @return The record set or an array of records

      def fetch_records(ids)
        model.where(id: ids)
      end

      # Adds the provided block as index scope to the list of index scopes.
      # All index scopes will automatically be applied to scopes, eg
      # ActiveRecord::Relation's, provided to #import or #index. This can be
      # used to preload associations that are used when serializing records or
      # to restrict the records you want to index.
      #
      # @example Preloading an association
      #   index_scope { preload(:user) }
      #
      #   CommentIndex.import(Comment.all) # => CommentIndex.import(Comment.preload(:user))
      #
      # @example Restricting records
      #   index_scope { where(public: true) }
      #
      #   CommentIndex.import(Comment.all) # => CommentIndex.import(Comment.where(public: true))
      #
      # @param block The block implementing the index scope

      def index_scope(&block)
        if block_given?
          self.index_scopes = index_scopes + [block]
        else
          index_scope_for(model)
        end
      end

      # @api private
      #
      # Applies all index scopes to the scope provided. The scope eg is an
      # ActiveRecord::Relation, but can as well be any other kind of scope
      # depending on which ORM is used, if any.
      #
      # @param scope The scope to which the index scopes should be applied to
      # @return A new scope with all index scopes applied

      def index_scope_for(scope)
        index_scopes.inject(scope) { |memo, cur| memo.instance_exec(memo, &cur) }
      end

      # @api private
      #
      # Creates an ElasticSearch::Relation for the current index, which is used
      # as a base for chaining relation methods.
      #
      # @return [ElasticSearch::Relation] The base for chaining relation methods

      def relation
        ElasticSearch::Relation.new(:target => self)
      end

      delegate :profile, :where, :where_not, :filter, :range, :match_all, :exists, :exists_not, :post_where, :post_where_not, :post_filter, :post_range,
        :post_exists, :post_exists_not, :aggregate, :scroll, :source, :includes, :eager_load, :preload, :sort, :resort, :order, :reorder, :offset, :limit,
        :paginate, :search, :highlight, :suggest, :custom, :find_in_batches, :find_each, :failsafe, :total_entries, :records, :to => :relation

      # Override to specify the type name used within ElasticSearch. Recap,
      # this gem uses an individual index for each index class, because
      # ElasticSearch requires to have the same mapping for the same field
      # name, even if the field is living in different types of the same index.
      #
      # @return [String] The name used for the type within the index

      def type_name
        raise NotImplementedError
      end

      # Returns the base name of the index within ElasticSearch, ie the index
      # name without prefix. Equals #type_name by default.
      #
      # @return [String] The base name of the index, ie without prefix

      def index_name
        type_name
      end

      # @api private
      #
      # Returns the full name of the index within ElasticSearch, ie with prefix
      # specified via ElasticSearch::Config[:index_prefix].
      #
      # @return [String] The full index name

      def index_name_with_prefix
        "#{ElasticSearch::Config[:index_prefix]}#{index_name}"
      end

      # Override to specify index settings like number of shards, analyzers,
      # refresh interval, etc.
      #
      # @example
      #   def self.index_settings
      #     {
      #       settings: {
      #         number_of_shards: 1
      #       }
      #     }
      #   end
      #
      # @return [Hash] The index settings

      def index_settings
        {}
      end

      # Returns whether or not the associated ElasticSearch index already
      # exists.
      #
      # @return [Boolean] Whether or not the index exists

      def index_exists?
        get_mapping

        true
      rescue RestClient::NotFound
        false
      end

      # Fetches the index settings from ElasticSearch. Sends a GET request to
      # index_url/_settings. Raises RestClient specific exceptions in case any
      # errors occur.
      #
      # @return [Hash] The index settings

      def get_index_settings
        JSON.parse RestClient.get("#{index_url}/_settings", content_type: "application/json")
      end

      # Creates the index within ElasticSearch and applies index settings, if
      # specified. Raises RestClient specific exceptions in case any errors
      # occur.

      def create_index
        RestClient.put index_url, JSON.generate(index_settings), content_type: "application/json"
      end

      # Updates the index settings within ElasticSearch according to the index
      # settings specified. Raises RestClient specific exceptions in case any
      # errors occur.

      def update_index_settings
        RestClient.put "#{index_url}/_settings", JSON.generate(index_settings), content_type: "application/json"
      end

      # Deletes the index from ElasticSearch. Raises RestClient specific
      # exceptions in case any errors occur.

      def delete_index
        RestClient.delete index_url, content_type: "application/json"
      end

      # Specifies a type mapping. Override to specify a custom mapping.
      #
      # @example
      #   def self.mapping
      #     {
      #       comments: {
      #         _all: {
      #           enabled: false
      #         },
      #         properties: {
      #           email: { type: "string", analyzer: "custom_analyzer" }
      #         }
      #       }
      #     }
      #   end

      def mapping
        { type_name => {} }
      end

      # Updates the type mapping within ElasticSearch according to the mapping
      # currently specified. Raises RestClient specific exceptions in case any
      # errors occur.

      def update_mapping
        RestClient.put "#{type_url}/_mapping", JSON.generate(mapping), content_type: "application/json"
      end

      # Retrieves the current type mapping from ElasticSearch. Raises RestClient
      # specific exceptions in case any errors occur.
      #
      # @return [Hash] The current type mapping

      def get_mapping
        JSON.parse RestClient.get("#{type_url}/_mapping", content_type: "application/json")
      end

      # Retrieves the document specified by id from ElasticSearch. Raises RestClient
      # specific exceptions in case any errors occur.
      #
      # @return [Hash] The specified document

      def get(id, params = {})
        JSON.parse RestClient.get("#{type_url}/#{id}", params: params, content_type: "application/json")
      end

      # Sends a index refresh request to ElasticSearch. Raises RestClient
      # specific exceptions in case any errors occur.

      def refresh
        RestClient.post "#{index_url}/_refresh", "{}", content_type: "application/json"
      end

      # Indexes the given record set, array of records or individual record.
      # Alias for #index.
      #
      # @see #index See #index for more details

      def import(*args)
        index(*args)
      end

      # Indexes the given record set, array of records or individual record. A
      # record set usually is an ActiveRecord::Relation, but can be any other
      # ORM as well. Uses the ElasticSearch bulk API no matter what is
      # provided. Refreshes the index if the environment is set to test.
      # Raises RestClient specific exceptions in case any errors occur.
      #
      # @see #fetch_records See #fetch_records for other/custom ORMs
      # @see #record_id See #record_id for other/custom ORMs
      # @see ElasticSearch::Config See ElasticSearch::Config for changing the
      #   environment
      #
      # @example
      #   CommentIndex.import Comment.all
      #   CommentIndex.import [comment1, comment2]
      #   CommentIndex.import Comment.first
      #   CommentIndex.import Comment.all, ignore_errors: [409]
      #   CommentIndex.import Comment.all, raise: false
      #
      # @param scope A record set, array of records or individual record to index
      # @param options [Hash] Specifies options regarding the bulk indexing
      # @option options ignore_errors [Array] Specifies an array of http status
      #   codes that shouldn't raise any exceptions, like eg 409 for conflicts,
      #   ie when optimistic concurrency control is used.
      # @option options raise [Boolean] Prevents any exceptions from being
      #   raised. Please note that this only applies to the bulk response, not to
      #   the request in general, such that connection errors, etc will still
      #   raise.
      # @param _index_options [Hash] Provides custom index options for eg
      #   routing, versioning, etc

      def index(scope, options = {}, _index_options = {})
        bulk options do |indexer|
          each_record(scope, index_scope: true) do |object|
            indexer.index record_id(object), JSON.generate(serialize(object)), index_options(object).merge(_index_options)
          end
        end

        scope
      end

      # Indexes the given record set, array of records or individual record
      # using ElasticSearch's create operation via the Bulk API, such that the
      # request will fail if a record with a particular primary key already
      # exists in ElasticSearch.
      #
      # @see #index See #index for more details regarding available
      #   params and return values

      def create(scope, options = {}, _index_options = {})
        bulk options do |indexer|
          each_record(scope, index_scope: true) do |object|
            indexer.create record_id(object), JSON.generate(serialize(object)), index_options(object).merge(_index_options)
          end
        end

        scope
      end

      # Indexes the given record set, array of records or individual record
      # using ElasticSearch's update operation via the Bulk API, such that the
      # request will fail if a record you want to update does not already exist
      # in ElasticSearch.
      #
      # @see #index See #index for more details regarding available
      #   params and return values

      def update(scope, options = {}, _index_options = {})
        bulk options do |indexer|
          each_record(scope, index_scope: true) do |object|
            indexer.update record_id(object), JSON.generate(:doc => serialize(object)), index_options(object).merge(_index_options)
          end
        end

        scope
      end

      # Deletes the given record set, array of records or individual record
      # from ElasticSearch using the Bulk API.
      #
      # @see #index See #index for more details regarding available
      #   params and return values

      def delete(scope, options = {}, _index_options = {})
        bulk options do |indexer|
          each_record(scope) do |object|
            indexer.delete record_id(object), index_options(object).merge(_index_options)
          end
        end

        scope
      end

      # Initiates and yields the bulk object, such that index, import, create,
      # update and delete requests can be appended to the bulk request. Sends a
      # refresh request afterwards if the current environment is set to test.
      #
      # @example
      #   CommentIndex.bulk ignore_errors: [409] do |bulk|
      #     bulk.create comment.id, JSON.generate(CommentIndex.serialize(comment)),
      #       version: comment.version, version_type: "external_gte"
      #
      #     bulk.delete ...
      #   end
      #
      # @param options [Hash] Specifies options regarding the bulk indexing
      # @option options ignore_errors [Array] Specifies an array of http status
      #   codes that shouldn't raise any exceptions, like eg 409 for conflicts,
      #   ie when optimistic concurrency control is used.
      # @option options raise [Boolean] Prevents any exceptions from being
      #   raised. Please note that this only applies to the bulk response, not to
      #   the request in general, such that connection errors, etc will still
      #   raise.
      #
      # @see ElasticSearch::Config See ElasticSearch::Config for changing the
      #   environment and bulk limit
 
      def bulk(options = {})
        ElasticSearch::Bulk.new("#{type_url}/_bulk", ElasticSearch::Config[:bulk_limit], options) do |indexer|
          yield indexer
        end

        refresh if ElasticSearch::Config[:environment] == "test"
      end

      # Returns the full ElasticSearch type URL, ie base URL, index name with
      # prefix and type name.
      #
      # @return [String] The ElasticSearch type URL

      def type_url
        "#{index_url}/#{type_name}"
      end

      # Returns the ElasticSearch index URL, ie base URL and index name with
      # prefix.
      #
      # @return [String] The ElasticSearch index URL

      def index_url
        "#{base_url}/#{index_name_with_prefix}"
      end

      # Returns the ElasticSearch base URL, ie protcol and host with port.
      #
      # @return [String] The ElasticSearch base URL

      def base_url
        ElasticSearch::Config[:base_url]
      end
    end
  end
end

