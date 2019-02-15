
module SearchFlip
  class Connection
    attr_reader :base_url

    def initialize(base_url: SearchFlip::Config[:base_url])
      @base_url = base_url
    end

    # Queries and returns the ElasticSearch version used.
    #
    # @example
    #   SearchFlip.version # => e.g. 2.4.1
    #
    # @return [String] The ElasticSearch version

    def version
      @version ||= SearchFlip::HTTPClient.get("#{base_url}/").parse["version"]["number"]
    end

    # Uses the ElasticSearch Multi Search API to execute multiple search requests
    # within a single request. Raises SearchFlip::ResponseError in case any
    # errors occur.
    #
    # @example
    #   SearchFlip.msearch [ProductIndex.match_all, CommentIndex.match_all]
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
        SearchFlip::HTTPClient
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
    #   SearchFlip.update_aliases(actions: [
    #     { remove: { index: "test1", alias: "alias1" }},
    #     { add: { index: "test2", alias: "alias1" }}
    #   ])
    #
    # @param payload [Hash] The raw request payload
    #
    # @return [Hash] The raw response

    def update_aliases(payload)
      SearchFlip::HTTPClient
        .headers(accept: "application/json", content_type: "application/json")
        .post("#{base_url}/_aliases", body: SearchFlip::JSON.generate(payload))
        .parse
    end

    # Fetches information about the specified index aliases. Raises
    # SearchFlip::ResponseError in case any errors occur.
    #
    # @example
    #   SearchFlip.get_aliases(alias_name: "some_alias")
    #   SearchFlip.get_aliases(index_name: "index1,index2")
    #
    # @param alias_name [String] The alias or comma separated list of alias names
    # @param index_name [String] The index or comma separated list of index names
    #
    # @return [Hash] The raw response

    def get_aliases(index_name: "*", alias_name: "*")
      SearchFlip::HTTPClient
        .headers(accept: "application/json", content_type: "application/json")
        .get("#{base_url}/#{index_name}/_alias/#{alias_name}")
        .parse
    end

    # Returns whether or not the associated ElasticSearch alias already
    # exists.
    #
    # @example
    #   SearchFlip.alias_exists?("some_alias")
    #
    # @return [Boolean] Whether or not the alias exists

    def alias_exists?(alias_name)
      get_aliases(alias_name: alias_name)

      true
    rescue SearchFlip::ResponseError => e
      return false if e.code == 404

      raise e
    end
  end
end

