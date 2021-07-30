module SearchFlip
  # The SearchFlip::Criteria class serves the purpose of chaining various
  # filtering and aggregation methods. Each chainable method creates a new
  # criteria object until a method is called that finally sends the respective
  # request to Elasticsearch and returns the result.
  #
  # @example
  #   CommentIndex.where(public: true).sort(id: "desc").limit(1_000).records
  #   CommentIndex.range(:created_at, lt: Time.parse("2014-01-01").delete
  #   CommentIndex.search("hello world").total_entries
  #   CommentIndex.query(more_like_this: { "...", fields: ["description"] })]
  #   CommentIndex.exists(:user_id).paginate(page: 1, per_page: 100)
  #   CommentIndex.sort("_doc").find_each { |comment| "..." }

  class Criteria
    include Sortable
    include Sourceable
    include Highlightable
    include Explainable
    include Paginatable
    include Customable
    include Filterable
    include PostFilterable
    include Aggregatable
    extend Forwardable

    attr_accessor :target, :profile_value, :source_value, :suggest_values, :includes_values,
      :eager_load_values, :preload_values, :failsafe_value, :scroll_args, :terminate_after_value,
      :timeout_value, :preference_value, :search_type_value, :routing_value, :track_total_hits_value,
      :http_timeout_value

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
        [
          :profile_value, :failsafe_value, :terminate_after_value, :timeout_value, :offset_value,
          :limit_value, :scroll_args, :source_value, :preference_value, :search_type_value,
          :routing_value, :track_total_hits_value, :explain_value, :http_timeout_value
        ].each do |name|
          criteria.send(:"#{name}=", other.send(name)) unless other.send(name).nil?
        end

        [
          :sort_values, :includes_values, :preload_values, :eager_load_values, :must_values,
          :must_not_values, :filter_values, :post_must_values, :post_must_not_values,
          :post_filter_values
        ].each do |name|
          criteria.send(:"#{name}=", (criteria.send(name) || []) + other.send(name)) if other.send(name)
        end

        [:highlight_values, :suggest_values, :custom_value, :aggregation_values].each do |name|
          criteria.send(:"#{name}=", (criteria.send(name) || {}).merge(other.send(name))) if other.send(name)
        end
      end
    end

    # Specifies if or how many hits should be counted/tracked. Check out the
    # elasticsearch docs for futher details.
    #
    # @example
    #   CommentIndex.track_total_hits(true)
    #   CommentIndex.track_total_hits(10_000)
    #
    # @param value The value for track_total_hits
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def track_total_hits(value)
      fresh.tap do |criteria|
        criteria.track_total_hits_value = value
      end
    end

    # Specifies a preference value for the request. Check out the elasticsearch
    # docs for further details.
    #
    # @example
    #   CommentIndex.preference("_primary")
    #
    # @param value The preference value
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def preference(value)
      fresh.tap do |criteria|
        criteria.preference_value = value
      end
    end

    # Specifies the search type value for the request. Check out the elasticsearch
    # docs for further details.
    #
    # @example
    #   CommentIndex.search_type("dfs_query_then_fetch")
    #
    # @param value The search type value
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def search_type(value)
      fresh.tap do |criteria|
        criteria.search_type_value = value
      end
    end

    # Specifies the routing value for the request. Check out the elasticsearch
    # docs for further details.
    #
    # @example
    #   CommentIndex.routing("user_id")
    #
    # @param value The search type value
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def routing(value)
      fresh.tap do |criteria|
        criteria.routing_value = value
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

    # Specifies a http timeout, such that a SearchFlip::TimeoutError will be
    # thrown when the request times out.
    #
    # @example
    #   ProductIndex.http_timeout(3).search("hello world")
    #
    # @param value [Fixnum] The timeout value
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def http_timeout(value)
      fresh.tap do |criteria|
        criteria.http_timeout_value = value
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

    # @api private
    #
    # Convenience method to have a unified conversion api.
    #
    # @return [SearchFlip::Criteria] Simply returns self

    def criteria
      self
    end

    alias_method :all, :criteria

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

    ruby2_keywords def with_settings(*args)
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
      @request ||= begin
        res = {}

        if must_values || must_not_values || filter_values
          res[:query] = {
            bool: {
              must: must_values.to_a,
              must_not: must_not_values.to_a,
              filter: filter_values.to_a
            }.reject { |_, value| value.empty? }
          }
        end

        res.update(from: offset_value_with_default, size: limit_value_with_default)

        res[:track_total_hits] = track_total_hits_value unless track_total_hits_value.nil?
        res[:explain] = explain_value unless explain_value.nil?
        res[:timeout] = timeout_value if timeout_value
        res[:terminate_after] = terminate_after_value if terminate_after_value
        res[:highlight] = highlight_values if highlight_values
        res[:suggest] = suggest_values if suggest_values
        res[:sort] = sort_values if sort_values
        res[:aggregations] = aggregation_values if aggregation_values

        if post_must_values || post_must_not_values || post_filter_values
          res[:post_filter] = {
            bool: {
              must: post_must_values.to_a,
              must_not: post_must_not_values.to_a,
              filter: post_filter_values.to_a
            }.reject { |_, value| value.empty? }
          }
        end

        res[:_source] = source_value unless source_value.nil?
        res[:profile] = true if profile_value

        res.update(custom_value) if custom_value

        res
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
    # @param options [Hash] Additional suggestion options. Check out the Elasticsearch
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

    # Sends a delete by query request to Elasticsearch, such that all documents
    # matching the query get deleted. Please note, for certain Elasticsearch
    # versions you need to install the delete-by-query plugin to get support
    # for this feature. Refreshes the index if the auto_refresh is enabled.
    # Raises SearchFlip::ResponseError in case any errors occur.
    #
    # @see SearchFlip::Config See SearchFlip::Config for auto_refresh
    #
    # @example
    #   CommentIndex.range(lt: Time.parse("2014-01-01")).delete
    #   CommentIndex.where(public: false).delete

    def delete(params = {})
      dupped_request = request.dup
      dupped_request.delete(:from)
      dupped_request.delete(:size)

      http_request = connection.http_client
      http_request = http_request.timeout(http_timeout_value) if http_timeout_value

      if connection.version.to_i >= 5
        http_request.post("#{target.type_url}/_delete_by_query", params: request_params.merge(params), json: dupped_request)
      else
        http_request.delete("#{target.type_url}/_query", params: request_params.merge(params), json: dupped_request)
      end

      target.refresh if SearchFlip::Config[:auto_refresh]

      true
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

    # Fetches the records specified by the criteria in batches using the
    # ElasicSearch scroll API and yields each batch. The batch size and scroll
    # API timeout can be specified. Check out the Elasticsearch docs for
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
    #   long Elasticsearch will keep the request handle open.

    def find_in_batches(options = {})
      return enum_for(:find_in_batches, options) unless block_given?

      yield_in_batches(options) do |criteria|
        yield(criteria.records) if criteria.records.size > 0
      end
    end

    # Fetches the results specified by the criteria in batches using the
    # Elasticsearch scroll API and yields each batch. The batch size and scroll
    # API timeout can be specified. Checkout out the Elasticsearch docs for
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
    #   long Elasticsearch will keep the request handle open.

    def find_results_in_batches(options = {})
      return enum_for(:find_results_in_batches, options) unless block_given?

      yield_in_batches(options) do |criteria|
        yield criteria.results
      end
    end

    # Fetches the records specified by the relatin in batches using the
    # Elasticsearch scroll API and yields each record. The batch size and
    # scroll API timeout can be specified. Check out the Elasticsearch docs for
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
    #   long Elasticsearch will keep the request handle open.

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
    # Elasticsearch scroll API and yields each result. The batch size and scroll
    # API timeout can be specified. Checkout out the Elasticsearch docs for
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
    #   long Elasticsearch will keep the request handle open.

    def find_each_result(options = {})
      return enum_for(:find_each_result, options) unless block_given?

      find_results_in_batches options do |batch|
        batch.each do |result|
          yield result
        end
      end
    end

    # Executes the search request for the current criteria, ie sends the
    # request to Elasticsearch and returns the response. Connection and
    # response errors will be rescued if you specify the criteria to be
    # #failsafe, such that an empty response is returned instead.
    #
    # @example
    #   response = CommentIndex.search("hello world").execute
    #
    # @return [SearchFlip::Response] The response object

    def execute
      @response ||= begin
        Config[:instrumenter].instrument("request.search_flip", index: target, request: request) do |payload|
          response = execute!

          payload[:response] = response

          response
        end
      end
    end

    alias_method :response, :execute

    # Marks the criteria to be failsafe, ie certain exceptions raised due to
    # invalid queries, inavailability of Elasticsearch, etc get rescued and an
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
        criteria.instance_variable_set(:@request, nil)
        criteria.instance_variable_set(:@response, nil)
      end
    end

    def respond_to_missing?(name, *args)
      target.respond_to?(name, *args) || super
    end

    def method_missing(name, *args, &block)
      if target.respond_to?(name)
        merge(target.send(name, *args, &block))
      else
        super
      end
    end

    ruby2_keywords :method_missing

    def_delegators :response, :total_entries, :total_count, :current_page, :previous_page,
      :prev_page, :next_page, :first_page?, :last_page?, :out_of_range?, :total_pages,
      :hits, :ids, :count, :size, :length, :took, :aggregations, :suggestions,
      :scope, :results, :records, :scroll_id, :raw_response

    def_delegators :target, :connection

    private

    def execute!
      http_request = connection.http_client.headers(accept: "application/json")
      http_request = http_request.timeout(http_timeout_value) if http_timeout_value

      http_response =
        if scroll_args && scroll_args[:id]
          http_request.post(
            "#{connection.base_url}/_search/scroll",
            params: request_params,
            json: { scroll: scroll_args[:timeout], scroll_id: scroll_args[:id] }
          )
        elsif scroll_args
          http_request.post(
            "#{target.type_url}/_search",
            params: request_params.merge(scroll: scroll_args[:timeout]),
            json: request
          )
        else
          http_request.post("#{target.type_url}/_search", params: request_params, json: request)
        end

      SearchFlip::Response.new(self, SearchFlip::JSON.parse(http_response.to_s))
    rescue SearchFlip::ConnectionError, SearchFlip::TimeoutError, SearchFlip::ResponseError => e
      raise e unless failsafe_value

      SearchFlip::Response.new(self, "took" => 0, "hits" => { "total" => 0, "hits" => [] })
    end

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

    def request_params
      res = {}
      res[:preference] = preference_value if preference_value
      res[:search_type] = search_type_value if search_type_value
      res[:routing] = routing_value if routing_value
      res
    end
  end
end
