
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

    # Queries and returns the ElasticSearch version used.
    #
    # @example
    #   connection.version # => e.g. 2.4.1
    #
    # @return [String] The ElasticSearch version

    def version
      @version ||= http_client.headers(accept: "application/json").get("#{base_url}/").parse["version"]["number"]
    end

    # Queries and returns the ElasticSearch cluster health.
    #
    # @example
    #   connection.cluster_health # => { "status" => "green", ... }
    #
    # @return [Hash] The raw response

    def cluster_health
      http_client.headers(accept: "application/json").get("#{base_url}/_cluster/health").parse
    end

    # Uses the ElasticSearch Multi Search API to execute multiple search requests
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
          SearchFlip::JSON.generate(index: criteria.target.index_name_with_prefix, type: criteria.target.type_name),
          SearchFlip::JSON.generate(criteria.request)
        ]
      end

      payload = payload.join("\n")
      payload << "\n"

      raw_response =
        http_client
          .headers(accept: "application/json", content_type: "application/x-ndjson")
          .post("#{base_url}/_msearch", body: payload)

      raw_response.parse["responses"].map.with_index do |response, index|
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
      http_client
        .headers(accept: "application/json", content_type: "application/json")
        .post("#{base_url}/_aliases", body: SearchFlip::JSON.generate(payload))
        .parse
    end

    # Sends an analyze request to ElasticSearch. Raises
    # SearchFlip::ResponseError in case any errors occur.
    #
    # @example
    #   connection.analyze(analyzer: "standard", text: "this is a test")
    #
    # @return [Hash] The raw response

    def analyze(request, params = {})
      http_client.headers(accept: "application/json").post("#{base_url}/_analyze", json: request, params: params).parse
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
      res =
        http_client
          .headers(accept: "application/json", content_type: "application/json")
          .get("#{base_url}/#{index_name}/_alias/#{alias_name}")
          .parse

      Hashie::Mash.new(res)
    end

    # Returns whether or not the associated ElasticSearch alias already
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

    def get_indices(name = "*")
      http_client
        .headers(accept: "application/json", content_type: "application/json")
        .get("#{base_url}/_cat/indices/#{name}")
        .parse
    end

    alias_method :cat_indices, :get_indices

    # Creates the specified index within ElasticSearch and applies index
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

    # Closes the specified index within ElasticSearch. Raises
    # SearchFlip::ResponseError in case any errors occur
    #
    # @param index_name [String] The index name
    #
    # @return [Boolean] Returns true or raises SearchFlip::ResponseError

    def close_index(index_name)
      http_client.post("#{index_url(index_name)}/_close")

      true
    end

    # Opens the specified index within ElasticSearch. Raises
    # SearchFlip::ResponseError in case any errors occur
    #
    # @param index_name [String] The index name
    #
    # @return [Boolean] Returns true or raises SearchFlip::ResponseError

    def open_index(index_name)
      http_client.post("#{index_url(index_name)}/_open")

      true
    end

    # Updates the index settings within ElasticSearch according to the index
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

    # Fetches the index settings for the specified index from ElasticSearch.
    # Sends a GET request to index_url/_settings. Raises
    # SearchFlip::ResponseError in case any errors occur.
    #
    # @param index_name [String] The index name
    #
    # @return [Hash] The index settings

    def get_index_settings(index_name)
      http_client.headers(accept: "application/json").get("#{index_url(index_name)}/_settings").parse
    end

    # Sends a refresh request to ElasticSearch. Raises
    # SearchFlip::ResponseError in case any errors occur.
    #
    # @param index_names [String, Array] The optional index names to refresh
    # @return [Boolean] Returns true or raises SearchFlip::ResponseError

    def refresh(index_names = nil)
      http_client.post("#{index_names ? index_url(Array(index_names).join(",")) : base_url}/_refresh", json: {})

      true
    end

    # Updates the type mapping for the specified index and type within
    # ElasticSearch according to the specified mapping. Raises
    # SearchFlip::ResponseError in case any errors occur.
    #
    # @param index_name [String] The index name
    # @param type_name [String] The type name. Starting with Elasticsearch 7,
    #   the type name is optional.
    # @param mapping [Hash] The mapping
    # @param params [Hash] Optional url parameters
    #
    # @return [Boolean] Returns true or raises SearchFlip::ResponseError

    def update_mapping(index_name, type_name = nil, mapping)
      url = type_name ? type_url(index_name, type_name) : index_url(index_name)
      params = type_name ? { include_type_name: true } : {}

      http_client.put("#{url}/_mapping", params: params, json: mapping)

      true
    end

    # Retrieves the mapping for the specified index and type from
    # ElasticSearch. Raises SearchFlip::ResponseError in case any errors occur.
    #
    # @param index_name [String] The index name
    # @param type_name [String] The type name. Starting with Elasticsearch 7,
    #   the type name is optional.
    #
    # @return [Hash] The current type mapping

    def get_mapping(index_name, type_name = nil)
      url = type_name ? type_url(index_name, type_name) : index_url(index_name)
      params = type_name ? { include_type_name: true } : {}

      http_client.headers(accept: "application/json").get("#{url}/_mapping", params: params).parse
    end

    # Deletes the specified index from ElasticSearch. Raises
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

    # Returns the full ElasticSearch type URL, ie base URL, index name with
    # prefix and type name.
    #
    # @param index_name [String] The index name
    # @param type_name [String] The type name
    #
    # @return [String] The ElasticSearch type URL

    def type_url(index_name, type_name)
      "#{index_url(index_name)}/#{type_name}"
    end

    # Returns the ElasticSearch index URL for the specified index name, ie base
    # URL and index name with prefix.
    #
    # @param index_name [String] The index name
    #
    # @return [String] The ElasticSearch index URL

    def index_url(index_name)
      "#{base_url}/#{index_name}"
    end
  end
end

