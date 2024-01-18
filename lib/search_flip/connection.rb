module SearchFlip
  class Connection
    attr_reader :base_url, :http_client, :bulk_limit, :bulk_max_mb

    # Creates a new connection.
    #
    # @example
    #   SearchFlip::Connection.new(base_url: "http://elasticsearch.host:9200")
    #
    # @param options [Hash] A hash containing the config options
    # @option options base_url [String] The base url for the connection
    # @option options http_client [SearchFlip::HTTPClient] An optional http client instance
    # @option options bulk_max_mb [Fixnum] An optional MB limit for bulk requests

    def initialize(options = {})
      @base_url = options[:base_url] || SearchFlip::Config[:base_url]
      @http_client = options[:http_client] || SearchFlip::HTTPClient.new
      @bulk_limit = options[:bulk_limit] || SearchFlip::Config[:bulk_limit]
    end

    # Queries and returns the Elasticsearch distribution used.
    #
    # @example
    #   connection.distribution # => e.g. "opensearch"
    #
    # @return [String] The Elasticsearch distribution

    def distribution
      @distribution ||= SearchFlip::JSON.parse(version_response.to_s)["version"]["distribution"]
    end

    # Queries and returns the Elasticsearch version used.
    #
    # @example
    #   connection.version # => e.g. "2.4.1"
    #
    # @return [String] The Elasticsearch version

    def version
      @version ||= SearchFlip::JSON.parse(version_response.to_s)["version"]["number"]
    end

    # Queries and returns the Elasticsearch cluster health.
    #
    # @example
    #   connection.cluster_health # => { "status" => "green", ... }
    #
    # @return [Hash] The raw response

    def cluster_health
      response = http_client.headers(accept: "application/json").get("#{base_url}/_cluster/health")

      SearchFlip::JSON.parse(response.to_s)
    end

    # Uses the Elasticsearch Multi Search API to execute multiple search requests
    # within a single request. Raises SearchFlip::ResponseError in case any
    # errors occur.
    #
    # @example
    #   connection.msearch [ProductIndex.match_all, CommentIndex.match_all]
    #
    # @param criterias [Array<SearchFlip::Criteria>] An array of search
    #   queries to execute in parallel
    #
    # @return [Array<SearchFlip::Response>] An array of responses

    def msearch(criterias)
      payload = criterias.flat_map do |criteria|
        [
          SearchFlip::JSON.generate(index: criteria.target.index_name_with_prefix, **(distribution.nil? && version.to_i < 8 ? { type: criteria.target.type_name } : {})),
          SearchFlip::JSON.generate(criteria.request)
        ]
      end

      payload = payload.join("\n")
      payload << "\n"

      raw_response =
        http_client
          .headers(accept: "application/json", content_type: "application/x-ndjson")
          .post("#{base_url}/_msearch", body: payload)

      SearchFlip::JSON.parse(raw_response.to_s)["responses"].map.with_index do |response, index|
        SearchFlip::Response.new(criterias[index], response)
      end
    end

    # Used to manipulate, ie add and remove index aliases. Raises an
    # SearchFlip::ResponseError in case any errors occur.
    #
    # @example
    #   connection.update_aliases(actions: [
    #     { remove: { index: "test1", alias: "alias1" }},
    #     { add: { index: "test2", alias: "alias1" }}
    #   ])
    #
    # @param payload [Hash] The raw request payload
    #
    # @return [Hash] The raw response

    def update_aliases(payload)
      response = http_client
        .headers(accept: "application/json", content_type: "application/json")
        .post("#{base_url}/_aliases", body: SearchFlip::JSON.generate(payload))

      SearchFlip::JSON.parse(response.to_s)
    end

    # Sends an analyze request to Elasticsearch. Raises
    # SearchFlip::ResponseError in case any errors occur.
    #
    # @example
    #   connection.analyze(analyzer: "standard", text: "this is a test")
    #
    # @return [Hash] The raw response

    def analyze(request, params = {})
      response = http_client
        .headers(accept: "application/json")
        .post("#{base_url}/_analyze", json: request, params: params)

      SearchFlip::JSON.parse(response.to_s)
    end

    # Fetches information about the specified index aliases. Raises
    # SearchFlip::ResponseError in case any errors occur.
    #
    # @example
    #   connection.get_aliases(alias_name: "some_alias")
    #   connection.get_aliases(index_name: "index1,index2")
    #
    # @param alias_name [String] The alias or comma separated list of alias names
    # @param index_name [String] The index or comma separated list of index names
    #
    # @return [Hash] The raw response

    def get_aliases(index_name: "*", alias_name: "*")
      response = http_client
        .headers(accept: "application/json", content_type: "application/json")
        .get("#{base_url}/#{index_name}/_alias/#{alias_name}")

      SearchFlip::JSON.parse(response.to_s)
    end

    # Returns whether or not the associated Elasticsearch alias already
    # exists.
    #
    # @example
    #   connection.alias_exists?("some_alias")
    #
    # @return [Boolean] Whether or not the alias exists

    def alias_exists?(alias_name)
      http_client
        .headers(accept: "application/json", content_type: "application/json")
        .get("#{base_url}/_alias/#{alias_name}")

      true
    rescue SearchFlip::ResponseError => e
      return false if e.code == 404

      raise e
    end

    # Fetches information about the specified indices. Raises
    # SearchFlip::ResponseError in case any errors occur.
    #
    # @example
    #   connection.get_indices('prefix*')
    #
    # @return [Array] The raw response

    def get_indices(name = "*", params: {})
      response = http_client
        .headers(accept: "application/json", content_type: "application/json")
        .get("#{base_url}/_cat/indices/#{name}", params: params)

      SearchFlip::JSON.parse(response.to_s)
    end

    alias_method :cat_indices, :get_indices

    # Creates the specified index within Elasticsearch and applies index
    # settings, if specified. Raises SearchFlip::ResponseError in case any
    # errors occur.
    #
    # @param index_name [String] The index name
    # @param index_settings [Hash] The index settings
    # @param params [Hash] Optional url params
    #
    # @return [Boolean] Returns true or raises SearchFlip::ResponseError

    def create_index(index_name, index_settings = {}, params = {})
      http_client.put(index_url(index_name), params: params, json: index_settings)

      true
    end

    # Closes the specified index within Elasticsearch. Raises
    # SearchFlip::ResponseError in case any errors occur
    #
    # @param index_name [String] The index name
    #
    # @return [Boolean] Returns true or raises SearchFlip::ResponseError

    def close_index(index_name)
      http_client.post("#{index_url(index_name)}/_close")

      true
    end

    # Opens the specified index within Elasticsearch. Raises
    # SearchFlip::ResponseError in case any errors occur
    #
    # @param index_name [String] The index name
    #
    # @return [Boolean] Returns true or raises SearchFlip::ResponseError

    def open_index(index_name)
      http_client.post("#{index_url(index_name)}/_open")

      true
    end

    # Freezes the specified index within Elasticsearch. Raises
    # SearchFlip::ResponseError in case any errors occur
    #
    # @param index_name [String] The index name
    #
    # @return [Boolean] Returns true or raises SearchFlip::ResponseError

    def freeze_index(index_name)
      http_client.post("#{index_url(index_name)}/_freeze")

      true
    end

    # Unfreezes the specified index within Elasticsearch. Raises
    # SearchFlip::ResponseError in case any errors occur
    #
    # @param index_name [String] The index name
    #
    # @return [Boolean] Returns true or raises SearchFlip::ResponseError

    def unfreeze_index(index_name)
      http_client.post("#{index_url(index_name)}/_unfreeze")

      true
    end

    # Updates the index settings within Elasticsearch according to the index
    # settings specified. Raises SearchFlip::ResponseError in case any
    # errors occur.
    #
    # @param index_name [String] The index name to update the settings for
    # @param index_settings [Hash] The index settings
    #
    # @return [Boolean] Returns true or raises SearchFlip::ResponseError

    def update_index_settings(index_name, index_settings)
      http_client.put("#{index_url(index_name)}/_settings", json: index_settings)

      true
    end

    # Fetches the index settings for the specified index from Elasticsearch.
    # Sends a GET request to index_url/_settings. Raises
    # SearchFlip::ResponseError in case any errors occur.
    #
    # @param index_name [String] The index name
    #
    # @return [Hash] The index settings

    def get_index_settings(index_name)
      response = http_client
        .headers(accept: "application/json")
        .get("#{index_url(index_name)}/_settings")

      SearchFlip::JSON.parse(response.to_s)
    end

    # Sends a refresh request to Elasticsearch. Raises
    # SearchFlip::ResponseError in case any errors occur.
    #
    # @param index_names [String, Array] The optional index names to refresh
    # @return [Boolean] Returns true or raises SearchFlip::ResponseError

    def refresh(index_names = nil)
      http_client.post("#{index_names ? index_url(Array(index_names).join(",")) : base_url}/_refresh")

      true
    end

    # Updates the type mapping for the specified index and type within
    # Elasticsearch according to the specified mapping. Raises
    # SearchFlip::ResponseError in case any errors occur.
    #
    # @param index_name [String] The index name
    # @param mapping [Hash] The mapping
    # @param type_name [String] The type name. Starting with Elasticsearch 7,
    #   the type name is optional.
    #
    # @return [Boolean] Returns true or raises SearchFlip::ResponseError

    def update_mapping(index_name, mapping, type_name: nil)
      url = type_name && distribution.nil? && version.to_i < 8 ? type_url(index_name, type_name) : index_url(index_name)
      params = type_name && distribution.nil? && version.to_f >= 6.7 && version.to_i < 8 ? { include_type_name: true } : {}

      http_client.put("#{url}/_mapping", params: params, json: mapping)

      true
    end

    # Retrieves the mapping for the specified index and type from
    # Elasticsearch. Raises SearchFlip::ResponseError in case any errors occur.
    #
    # @param index_name [String] The index name
    # @param type_name [String] The type name. Starting with Elasticsearch 7,
    #   the type name is optional.
    #
    # @return [Hash] The current type mapping

    def get_mapping(index_name, type_name: nil)
      url = type_name && distribution.nil? && version.to_i < 8 ? type_url(index_name, type_name) : index_url(index_name)
      params = type_name && distribution.nil? && version.to_f >= 6.7 && version.to_i < 8 ? { include_type_name: true } : {}

      response = http_client.headers(accept: "application/json").get("#{url}/_mapping", params: params)

      SearchFlip::JSON.parse(response.to_s)
    end

    # Deletes the specified index from Elasticsearch. Raises
    # SearchFlip::ResponseError in case any errors occur.
    #
    # @param index_name [String] The index name
    #
    # @return [Boolean] Returns true or raises SearchFlip::ResponseError

    def delete_index(index_name)
      http_client.delete index_url(index_name)

      true
    end

    # Returns whether or not the specified index already exists.
    #
    # @param index_name [String] The index name
    #
    # @return [Boolean] Whether or not the index exists

    def index_exists?(index_name)
      http_client.headers(accept: "application/json").head(index_url(index_name))

      true
    rescue SearchFlip::ResponseError => e
      return false if e.code == 404

      raise e
    end

    # Initiates and yields a bulk object, such that index, import, create,
    # update and delete requests can be appended to the bulk request. Please
    # note that you need to manually pass the desired index name as well as
    # type name (depending on the Elasticsearch version) when using #bulk on a
    # connection object or Elasticsearch will return an error. After the bulk
    # requests are successfully processed all existing indices will
    # subsequently be refreshed when auto_refresh is enabled.
    #
    # @see SearchFlip::Config See SearchFlip::Config for auto_refresh
    #
    # @example
    #   connection = SearchFlip::Connection.new
    #
    #   connection.bulk ignore_errors: [409] do |bulk|
    #     bulk.create comment.id, CommentIndex.serialize(comment),
    #       _index: CommentIndex.index_name, version: comment.version, version_type: "external_gte"
    #
    #     bulk.delete product.id, _index: ProductIndex.index_name, routing: product.user_id
    #
    #     # ...
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

    def bulk(options = {})
      default_options = {
        http_client: http_client,
        bulk_limit: bulk_limit,
        bulk_max_mb: bulk_max_mb
      }

      SearchFlip::Bulk.new("#{base_url}/_bulk", default_options.merge(options)) do |indexer|
        yield indexer
      end

      refresh if SearchFlip::Config[:auto_refresh]
    end

    # Returns the full Elasticsearch type URL, ie base URL, index name with
    # prefix and type name.
    #
    # @param index_name [String] The index name
    # @param type_name [String] The type name
    #
    # @return [String] The Elasticsearch type URL

    def type_url(index_name, type_name)
      "#{index_url(index_name)}/#{type_name}"
    end

    # Returns the Elasticsearch index URL for the specified index name, ie base
    # URL and index name with prefix.
    #
    # @param index_name [String] The index name
    #
    # @return [String] The Elasticsearch index URL

    def index_url(index_name)
      "#{base_url}/#{index_name}"
    end

    private

    def version_response
      @version_response ||= http_client.headers(accept: "application/json").get("#{base_url}/")
    end
  end
end
