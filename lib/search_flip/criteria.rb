
module SearchFlip
  # The SearchFlip::Criteria class serves the purpose of chaining various
  # filtering and aggregation methods. Each chainable method creates a new
  # criteria object until a method is called that finally sends the respective
  # request to ElasticSearch and returns the result.
  #
  # @example
  #   CommentIndex.where(public: true).sort(id: "desc").limit(1_000).records
  #   CommentIndex.range(:created_at, lt: Time.parse("2014-01-01").delete
  #   CommentIndex.search("hello world").total_entries
  #   CommentIndex.query(more_like_this: { "...", fields: ["description"] })]
  #   CommentIndex.exists(:user_id).paginate(page: 1, per_page: 100)
  #   CommentIndex.sort("_doc").find_each { |comment| "..." }

  class Criteria
    include SearchFlip::Filterable
    include SearchFlip::PostFilterable
    include SearchFlip::Aggregatable
    extend Forwardable

    attr_accessor :target, :profile_value, :source_value, :sort_values, :highlight_values, :suggest_values, :offset_value, :limit_value,
      :includes_values, :eager_load_values, :preload_values, :failsafe_value, :scroll_args, :custom_value, :terminate_after_value, :timeout_value

    # Creates a new criteria while merging the attributes (constraints,
    # settings, etc) of the current criteria with the attributes of another one
    # passed as argument. For multi-value contstraints the resulting criteria
    # will include constraints of both criterias. For single-value constraints,
    # the values of the criteria passed as an argument are used.
    #
    # @example
    #   CommentIndex.where(approved: true).merge(CommentIndex.range(:created_at, gt: Time.parse("2015-01-01")))
    #   CommentIndex.aggregate(:user_id).merge(CommentIndex.where(admin: true))
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def merge(other)
      other = other.criteria

      fresh.tap do |criteria|
        criteria.profile_value = other.profile_value unless other.profile_value.nil?
        criteria.failsafe_value = other.failsafe_value unless other.failsafe_value.nil?
        criteria.terminate_after_value = other.terminate_after_value unless other.terminate_after_value.nil?
        criteria.timeout_value = other.timeout_value unless other.timeout_value.nil?
        criteria.offset_value = other.offset_value if other.offset_value
        criteria.limit_value = other.limit_value if other.limit_value
        criteria.scroll_args = other.scroll_args if other.scroll_args
        criteria.source_value = other.source_value if other.source_value

        criteria.sort_values = (criteria.sort_values || []) + other.sort_values if other.sort_values
        criteria.includes_values = (criteria.includes_values || []) + other.includes_values if other.includes_values
        criteria.preload_values = (criteria.preload_values || []) + other.preload_values if other.preload_values
        criteria.eager_load_values = (criteria.eager_load_values || []) + other.eager_load_values if other.eager_load_values
        criteria.search_values = (criteria.search_values || []) + other.search_values if other.search_values
        criteria.must_values = (criteria.must_values || []) + other.must_values if other.must_values
        criteria.must_not_values = (criteria.must_not_values || []) + other.must_not_values if other.must_not_values
        criteria.should_values = (criteria.should_values || []) + other.should_values if other.should_values
        criteria.filter_values = (criteria.filter_values || []) + other.filter_values if other.filter_values
        criteria.post_search_values = (criteria.post_search_values || []) + other.post_search_values if other.post_search_values
        criteria.post_must_values = (criteria.post_must_values || []) + other.post_must_values if other.post_must_values
        criteria.post_must_not_values = (criteria.post_must_not_values || []) + other.post_must_not_values if other.post_must_not_values
        criteria.post_should_values = (criteria.post_should_values || []) + other.post_should_values if other.post_should_values
        criteria.post_filter_values = (criteria.post_filter_values || []) + other.post_filter_values if other.post_filter_values

        criteria.highlight_values = (criteria.highlight_values || {}).merge(other.highlight_values) if other.highlight_values
        criteria.suggest_values = (criteria.suggest_values || {}).merge(other.suggest_values) if other.suggest_values
        criteria.custom_value = (criteria.custom_value || {}).merge(other.custom_value) if other.custom_value
        criteria.aggregation_values = (criteria.aggregation_values || {}).merge(other.aggregation_values) if other.aggregation_values
      end
    end

    # Specifies a query timeout, such that the processing will be stopped after
    # that timeout and only the results calculated up to that point will be
    # processed and returned.
    #
    # @example
    #   ProductIndex.timeout("3s").search("hello world")
    #
    # @param value [String] The timeout value
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def timeout(value)
      fresh.tap do |criteria|
        criteria.timeout_value = value
      end
    end

    # Specifies early query termination, such that the processing will be
    # stopped after the specified number of results has been accumulated.
    #
    # @example
    #   ProductIndex.terminate_after(10_000).search("hello world")
    #
    # @param value [Fixnum] The number of records to terminate after
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def terminate_after(value)
      fresh.tap do |criteria|
        criteria.terminate_after_value = value
      end
    end

    # Creates a new criteria while removing all specified scopes. Currently,
    # you can unscope :search, :post_search, :sort, :highlight, :suggest, :custom
    # and :aggregate.
    #
    # @example
    #   CommentIndex.search("hello world").aggregate(:username).unscope(:search, :aggregate)
    #
    # @param scopes [Symbol] All scopes that you want to remove
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def unscope(*scopes)
      unknown = scopes - [:search, :post_search, :sort, :highlight, :suggest, :custom, :aggregate]

      raise(ArgumentError, "Can't unscope #{unknown.join(", ")}") if unknown.size > 0

      scopes = scopes.to_set

      fresh.tap do |criteria|
        criteria.search_values = nil if scopes.include?(:search)
        criteria.post_search_values = nil if scopes.include?(:post_search)
        criteria.sort_values = nil if scopes.include?(:sort)
        criteria.hightlight_values = nil if scopes.include?(:highlight)
        criteria.suggest_values = nil if scopes.include?(:suggest)
        criteria.custom_values = nil if scopes.include?(:custom)
        criteria.aggregation_values = nil if scopes.include?(:aggregate)
      end
    end

    # @api private
    #
    # Convenience method to have a unified conversion api.
    #
    # @return [SearchFlip::Criteria] Simply returns self

    def criteria
      self
    end

    # Creates a new SearchFlip::Criteria.
    #
    # @param attributes [Hash] Attributes to initialize the Criteria with

    def initialize(attributes = {})
      attributes.each do |key, value|
        send "#{key}=", value
      end
    end

    # Allows to set query specific settings like e.g. connection and index
    # name. Please note, however, that this should only be used for special
    # cases and the subsequent query can not be serialized. Checkout
    # SearchFlip::Index.with_settings for more details.
    #
    # @example
    #   UserIndex.where("...").with_settings(connection: ProxyConnection)
    #
    # @return [SearchFlip::Criteria] Simply returns self

    def with_settings(*args)
      fresh.tap do |criteria|
        criteria.target = target.with_settings(*args)
      end
    end

    # Generates the request object from the attributes specified via chaining,
    # like eg offset, limit, query, filters, aggregations, etc and returns a
    # Hash that later gets serialized as JSON.
    #
    # @return [Hash] The generated request object

    def request
      res = {}

      if must_values || search_values || must_not_values || should_values || filter_values
        if connection.version.to_i >= 2
          res[:query] = {
            bool: {}
              .merge(must_values || search_values ? { must: (must_values || []) + (search_values || []) } : {})
              .merge(must_not_values ? { must_not: must_not_values } : {})
              .merge(should_values ? { should: should_values } : {})
              .merge(filter_values ? { filter: filter_values } : {})
          }
        else
          filters = (filter_values || []) + (must_not_values || []).map { |must_not_value| { not: must_not_value } }

          queries = {}
            .merge(must_values || search_values ? { must: (must_values || []) + (search_values || []) } : {})
            .merge(should_values ? { should: should_values } : {})

          res[:query] =
            if filters.size > 0
              {
                filtered: {}
                  .merge(queries.size > 0 ? { query: { bool: queries } } : {})
                  .merge(filter: filters.size > 1 ? { and: filters } : filters.first)
              }
            else
              { bool: queries }
            end
        end
      end

      res.update from: offset_value_with_default, size: limit_value_with_default

      res[:timeout] = timeout_value if timeout_value
      res[:terminate_after] = terminate_after_value if terminate_after_value
      res[:highlight] = highlight_values if highlight_values
      res[:suggest] = suggest_values if suggest_values
      res[:sort] = sort_values if sort_values
      res[:aggregations] = aggregation_values if aggregation_values

      if post_must_values || post_search_values || post_must_not_values || post_should_values || post_filter_values
        if connection.version.to_i >= 2
          res[:post_filter] = {
            bool: {}
              .merge(post_must_values || post_search_values ? { must: (post_must_values || []) + (post_search_values || []) } : {})
              .merge(post_must_not_values ? { must_not: post_must_not_values } : {})
              .merge(post_should_values ? { should: post_should_values } : {})
              .merge(post_filter_values ? { filter: post_filter_values } : {})
          }
        else
          post_filters = (post_filter_values || []) + (post_must_not_values || []).map { |post_must_not_value| { not: post_must_not_value } }

          post_queries = {}
            .merge(post_must_values || post_search_values ? { must: (post_must_values || []) + (post_search_values || []) } : {})
            .merge(post_should_values ? { should: post_should_values } : {})

          post_filters_and_queries = post_filters + (post_queries.size > 0 ? [bool: post_queries] : [])

          res[:post_filter] = post_filters_and_queries.size > 1 ? { and: post_filters_and_queries } : post_filters_and_queries.first
        end
      end

      res[:_source] = source_value unless source_value.nil?
      res[:profile] = true if profile_value

      res.update(custom_value) if custom_value

      res
    end

    # Adds highlighting of the given fields to the request.
    #
    # @example
    #   CommentIndex.highlight([:title, :message])
    #   CommentIndex.highlight(:title).highlight(:description)
    #   CommentIndex.highlight(:title, require_field_match: false)
    #   CommentIndex.highlight(title: { type: "fvh" })
    #
    # @example
    #   query = CommentIndex.highlight(:title).search("hello")
    #   query.results[0].highlight.title # => "<em>hello</em> world"
    #
    # @param fields [Hash, Array, String, Symbol] The fields to highligt.
    #   Supports raw ElasticSearch values by passing a Hash.
    #
    # @param options [Hash] Extra highlighting options. Check out the ElasticSearch
    #   docs for further details.
    #
    # @return [SearchFlip::Criteria] A new criteria including the highlighting

    def highlight(fields, options = {})
      fresh.tap do |criteria|
        criteria.highlight_values = (criteria.highlight_values || {}).merge(options)

        hash =
          if fields.is_a?(Hash)
            fields
          elsif fields.is_a?(Array)
            fields.each_with_object({}) { |field, h| h[field] = {} }
          else
            { fields => {} }
          end

        criteria.highlight_values[:fields] = (criteria.highlight_values[:fields] || {}).merge(hash)
      end
    end

    # Adds a suggestion section with the given name to the request.
    #
    # @example
    #   query = CommentIndex.suggest(:suggestion, text: "helo", term: { field: "message" })
    #   query.suggestions(:suggestion).first["text"] # => "hello"
    #
    # @param name [String, Symbol] The name of the suggestion section
    #
    # @param options [Hash] Additional suggestion options. Check out the ElasticSearch
    #   docs for further details.
    #
    # @return [SearchFlip::Criteria] A new criteria including the suggestion section

    def suggest(name, options = {})
      fresh.tap do |criteria|
        criteria.suggest_values = (criteria.suggest_values || {}).merge(name => options)
      end
    end

    # Sets whether or not query profiling should be enabled.
    #
    # @example
    #   query = CommentIndex.profile(true)
    #   query.raw_response["profile"] # => { "shards" => ... }
    #
    # @param value [Boolean] Whether query profiling should be enabled or not
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def profile(value)
      fresh.tap do |criteria|
        criteria.profile_value = value
      end
    end

    # Adds scrolling to the request with or without an already existing scroll
    # id and using the specified timeout.
    #
    # @example
    #   query = CommentIndex.scroll(timeout: "5m")
    #
    #   until query.records.empty?
    #     # ...
    #
    #     query = query.scroll(id: query.scroll_id, timeout: "5m")
    #   end
    #
    # @param id [String, nil] The scroll id of the last request returned by
    #   SearchFlip or nil
    #
    # @param timeout [String] The timeout of the scroll request, ie. how long
    #   SearchFlip should keep the scroll handle open
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def scroll(id: nil, timeout: "1m")
      fresh.tap do |criteria|
        criteria.scroll_args = { id: id, timeout: timeout }
      end
    end

    # Sends a delete by query request to ElasticSearch, such that all documents
    # matching the query get deleted. Please note, for certain ElasticSearch
    # versions you need to install the delete-by-query plugin to get support
    # for this feature. Refreshes the index if the auto_refresh is enabled.
    # Raises SearchFlip::ResponseError in case any errors occur.
    #
    # @see SearchFlip::Config See SearchFlip::Config for auto_refresh
    #
    # @example
    #   CommentIndex.range(lt: Time.parse("2014-01-01")).delete
    #   CommentIndex.where(public: false).delete

    def delete
      dupped_request = request.dup
      dupped_request.delete(:from)
      dupped_request.delete(:size)

      if connection.version.to_i >= 5
        connection.http_client.post("#{target.type_url}/_delete_by_query", json: dupped_request)
      else
        connection.http_client.delete("#{target.type_url}/_query", json: dupped_request)
      end

      target.refresh if SearchFlip::Config[:auto_refresh]

      true
    end

    # Use to specify which fields of the source document you want ElasticSearch
    # to return for each matching result.
    #
    # @example
    #   CommentIndex.source([:id, :message]).search("hello world")
    #   CommentIndex.source(exclude: "description")
    #   CommentIndex.source(false)
    #
    # @param value Pass any allowed value to restrict the returned source
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def source(value)
      fresh.tap do |criteria|
        criteria.source_value = value
      end
    end

    # Specify associations of the target model you want to include via
    # ActiveRecord's or other ORM's mechanisms when records get fetched from
    # the database.
    #
    # @example
    #   CommentIndex.includes(:user, :post).records
    #   PostIndex.includes(:comments => :user).records
    #
    # @param args The args that get passed to the includes method of
    #   ActiveRecord or other ORMs
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def includes(*args)
      fresh.tap do |criteria|
        criteria.includes_values = (includes_values || []) + args
      end
    end

    # Specify associations of the target model you want to eager load via
    # ActiveRecord's or other ORM's mechanisms when records get fetched from
    # the database.
    #
    # @example
    #   CommentIndex.eager_load(:user, :post).records
    #   PostIndex.eager_load(:comments => :user).records
    #
    # @param args The args that get passed to the eager load method of
    #   ActiveRecord or other ORMs
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def eager_load(*args)
      fresh.tap do |criteria|
        criteria.eager_load_values = (eager_load_values || []) + args
      end
    end

    # Specify associations of the target model you want to preload via
    # ActiveRecord's or other ORM's mechanisms when records get fetched from
    # the database.
    #
    # @example
    #   CommentIndex.preload(:user, :post).records
    #   PostIndex.includes(:comments => :user).records
    #
    # @param args The args that get passed to the preload method of
    #   ActiveRecord or other ORMs
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def preload(*args)
      fresh.tap do |criteria|
        criteria.preload_values = (preload_values || []) + args
      end
    end

    # Specify the sort order you want ElasticSearch to use for sorting the
    # results. When you call this multiple times, the sort orders are appended
    # to the already existing ones. The sort arguments get passed to
    # ElasticSearch without modifications, such that you can use sort by
    # script, etc here as well.
    #
    # @example Default usage
    #   CommentIndex.sort(:user_id, :id)
    #
    #   # Same as
    #
    #   CommentIndex.sort(:user_id).sort(:id)
    #
    # @example Default hash usage
    #   CommentIndex.sort(user_id: "asc").sort(id: "desc")
    #
    #   # Same as
    #
    #   CommentIndex.sort({ user_id: "asc" }, { id: "desc" })
    #
    # @example Sort by native script
    #   CommentIndex.sort("_script" => "sort_script", lang: "native", order: "asc", type: "number")
    #
    # @param args The sort values that get passed to ElasticSearch
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def sort(*args)
      fresh.tap do |criteria|
        criteria.sort_values = (sort_values || []) + args
      end
    end

    alias_method :order, :sort

    # Specify the sort order you want ElasticSearch to use for sorting the
    # results with already existing sort orders being removed.
    #
    # @example
    #   CommentIndex.sort(user_id: "asc").resort(id: "desc")
    #
    #   # Same as
    #
    #   CommentIndex.sort(id: "desc")
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria
    #
    # @see #sort See #sort for more details

    def resort(*args)
      fresh.tap do |criteria|
        criteria.sort_values = args
      end
    end

    alias_method :reorder, :resort

    # Adds a fully custom field/section to the request, such that upcoming or
    # minor ElasticSearch features as well as other custom requirements can be
    # used without having yet specialized criteria methods.
    #
    # @note Use with caution, because using #custom will potentiall override
    #   other sections like +aggregations+, +query+, +sort+, etc if you use the
    #   the same section names.
    #
    # @example
    #   CommentIndex.custom(section: { argument: "value" }).request
    #   => {:section=>{:argument=>"value"},...}
    #
    # @param hash [Hash] The custom section that is added to the request
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def custom(hash)
      fresh.tap do |criteria|
        criteria.custom_value = (custom_value || {}).merge(hash)
      end
    end

    # Sets the request offset, ie SearchFlip's from parameter that is used
    # to skip results in the result set from being returned.
    #
    # @example
    #   CommentIndex.offset(100)
    #
    # @param value [Fixnum] The offset value, ie the number of results that are
    #   skipped in the result set
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def offset(value)
      fresh.tap do |criteria|
        criteria.offset_value = value.to_i
      end
    end

    # Returns the offset value or, if not yet set,  the default limit value (0).
    #
    # @return [Fixnum] The offset value

    def offset_value_with_default
      (offset_value || 0).to_i
    end

    # Sets the request limit, ie ElasticSearch's size parameter that is used
    # to restrict the results that get returned.
    #
    # @example
    #   CommentIndex.limit(100)
    #
    # @param value [Fixnum] The limit value, ie the max number of results that
    #   should be returned
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def limit(value)
      fresh.tap do |criteria|
        criteria.limit_value = value.to_i
      end
    end

    # Returns the limit value or, if not yet set, the default limit value (30).
    #
    # @return [Fixnum] The limit value

    def limit_value_with_default
      (limit_value || 30).to_i
    end

    # Sets pagination parameters for the criteria by using offset and limit,
    # ie ElasticSearch's from and size parameters.
    #
    # @example
    #   CommentIndex.paginate(page: 3)
    #   CommentIndex.paginate(page: 5, per_page: 60)
    #
    # @param page [#to_i] The current page
    # @param per_page [#to_i] The number of results per page
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def paginate(page:, per_page: limit_value_with_default)
      page = [page.to_i, 1].max
      per_page = per_page.to_i

      offset((page - 1) * per_page).limit(per_page)
    end

    def page(value)
      paginate(page: value)
    end

    def per(value)
      paginate(page: offset_value_with_default / limit_value_with_default + 1, per_page: value)
    end

    # Fetches the records specified by the criteria in batches using the
    # ElasicSearch scroll API and yields each batch. The batch size and scroll
    # API timeout can be specified. Check out the ElasticSearch docs for
    # further details.
    #
    # @example
    #   CommentIndex.search("hello world").find_in_batches(batch_size: 100) do |batch|
    #     # ...
    #   end
    #
    # @param options [Hash] The options to control the fetching of batches
    # @option options batch_size [Fixnum] The number of records to fetch per
    #   batch. Uses #limit to control the batch size.
    # @option options timeout [String] The timeout per scroll request, ie how
    #   long ElasticSearch will keep the request handle open.

    def find_in_batches(options = {})
      return enum_for(:find_in_batches, options) unless block_given?

      yield_in_batches(options) do |criteria|
        yield(criteria.records) if criteria.records.size > 0
      end
    end

    # Fetches the results specified by the criteria in batches using the
    # ElasticSearch scroll API and yields each batch. The batch size and scroll
    # API timeout can be specified. Checkout out the ElasticSearch docs for
    # further details.
    #
    # @example
    #   CommentIndex.search("hello world").find_results_in_batches(batch_size: 100) do |batch|
    #     # ...
    #   end
    #
    # @param options [Hash] The options to control the fetching of batches
    # @option options batch_size [Fixnum] The number of records to fetch per
    #   batch. Uses #limit to control the batch size.
    # @option options timeout [String] The timeout per scroll request, ie how
    #   long ElasticSearch will keep the request handle open.

    def find_results_in_batches(options = {})
      return enum_for(:find_results_in_batches, options) unless block_given?

      yield_in_batches(options) do |criteria|
        yield criteria.results
      end
    end

    # Fetches the records specified by the relatin in batches using the
    # ElasticSearch scroll API and yields each record. The batch size and
    # scroll API timeout can be specified. Check out the ElasticSearch docs for
    # further details.
    #
    # @example
    #   CommentIndex.search("hello world").find_each(batch_size: 100) do |record|
    #     # ...
    #   end
    #
    # @param options [Hash] The options to control the fetching of batches
    # @option options batch_size [Fixnum] The number of records to fetch per
    #   batch. Uses #limit to control the batch size.
    # @option options timeout [String] The timeout per scroll request, ie how
    #   long ElasticSearch will keep the request handle open.

    def find_each(options = {})
      return enum_for(:find_each, options) unless block_given?

      find_in_batches options do |batch|
        batch.each do |record|
          yield record
        end
      end
    end

    alias_method :each, :find_each

    # Fetches the results specified by the criteria in batches using the
    # ElasticSearch scroll API and yields each result. The batch size and scroll
    # API timeout can be specified. Checkout out the ElasticSearch docs for
    # further details.
    #
    # @example
    #   CommentIndex.search("hello world").find_each_result(batch_size: 100) do |result|
    #     # ...
    #   end
    #
    # @param options [Hash] The options to control the fetching of batches
    # @option options batch_size [Fixnum] The number of records to fetch per
    #   batch. Uses #limit to control the batch size.
    # @option options timeout [String] The timeout per scroll request, ie how
    #   long ElasticSearch will keep the request handle open.

    def find_each_result(options = {})
      return enum_for(:find_each_result, options) unless block_given?

      find_results_in_batches options do |batch|
        batch.each do |result|
          yield result
        end
      end
    end

    # Executes the search request for the current criteria, ie sends the
    # request to ElasticSearch and returns the response. Connection and
    # response errors will be rescued if you specify the criteria to be
    # #failsafe, such that an empty response is returned instead.
    #
    # @example
    #   response = CommentIndex.search("hello world").execute
    #
    # @return [SearchFlip::Response] The response object

    def execute
      @response ||= begin
        http_request = connection.http_client.headers(accept: "application/json")

        http_response =
          if scroll_args && scroll_args[:id]
            if connection.version.to_i >= 2
              http_request.post(
                "#{connection.base_url}/_search/scroll",
                json: { scroll: scroll_args[:timeout], scroll_id: scroll_args[:id] }
              )
            else
              http_request
                .headers(content_type: "text/plain")
                .post("#{connection.base_url}/_search/scroll", params: { scroll: scroll_args[:timeout] }, body: scroll_args[:id])
            end
          elsif scroll_args
            http_request.post(
              "#{target.type_url}/_search",
              params: { scroll: scroll_args[:timeout] },
              json: request
            )
          else
            http_request.post("#{target.type_url}/_search", json: request)
          end

        SearchFlip::Response.new(self, http_response.parse)
      rescue SearchFlip::ConnectionError, SearchFlip::ResponseError => e
        raise e unless failsafe_value

        SearchFlip::Response.new(self, "took" => 0, "hits" => { "total" => 0, "hits" => [] })
      end
    end

    alias_method :response, :execute

    # Marks the criteria to be failsafe, ie certain exceptions raised due to
    # invalid queries, inavailability of ElasticSearch, etc get rescued and an
    # empty criteria is returned instead.
    #
    # @see #execute See #execute for further details
    #
    # @example
    #   CommentIndex.search("invalid/request").execute
    #   # raises SearchFlip::ResponseError
    #
    #   # ...
    #
    #   CommentIndex.search("invalid/request").failsafe(true).execute
    #   # => #<SearchFlip::Response ...>
    #
    # @param value [Boolean] Whether or not the criteria should be failsafe
    #
    # @return [SearchFlip::Response] A newly created extended criteria

    def failsafe(value)
      fresh.tap do |criteria|
        criteria.failsafe_value = value
      end
    end

    # Returns a fresh, ie dupped, criteria with the response cache being
    # cleared.
    #
    # @example
    #   CommentIndex.search("hello world").fresh
    #
    # @return [SearchFlip::Response] A dupped criteria with the response
    #   cache being cleared

    def fresh
      dup.tap do |criteria|
        criteria.instance_variable_set(:@response, nil)
      end
    end

    def respond_to_missing?(name, *args)
      target.respond_to?(name, *args)
    end

    def method_missing(name, *args, &block)
      if target.respond_to?(name)
        merge(target.send(name, *args, &block))
      else
        super
      end
    end

    def_delegators :response, :total_entries, :total_count, :current_page, :previous_page,
      :prev_page, :next_page, :first_page?, :last_page?, :out_of_range?, :total_pages,
      :hits, :ids, :count, :size, :length, :took, :aggregations, :suggestions,
      :scope, :results, :records, :scroll_id, :raw_response

    def_delegators :target, :connection

    private

    def yield_in_batches(options = {})
      return enum_for(:yield_in_batches, options) unless block_given?

      batch_size = options[:batch_size] || 1_000
      timeout = options[:timeout] || "1m"

      criteria = limit(batch_size).scroll(timeout: timeout)

      until criteria.ids.empty?
        yield criteria.response

        criteria = criteria.scroll(id: criteria.scroll_id, timeout: timeout)
      end
    end
  end
end
