module SearchFlip
  # The SearchFlip::Response class wraps a raw SearchFlip response and
  # decorates it with methods for aggregations, hits, records, pagination, etc.

  class Response
    extend Forwardable

    attr_accessor :criteria, :response

    # @api private
    #
    # Initializes a new response object for the provided criteria and raw
    # Elasticsearch response.

    def initialize(criteria, response)
      self.criteria = criteria
      self.response = response
    end

    # Returns the raw response, ie a hash derived from the Elasticsearch JSON
    # response.
    #
    # @example
    #   CommentIndex.search("hello world").raw_response
    #   # => {"took"=>3, "timed_out"=>false, "_shards"=>"..."}
    #
    # @return [Hash] The raw response hash

    def raw_response
      response
    end

    # Returns the total number of results.
    #
    # @example
    #   CommentIndex.search("hello world").total_count
    #   # => 13
    #
    # @return [Fixnum] The total number of results

    def total_count
      hits["total"].is_a?(Hash) ? hits["total"]["value"] : hits["total"]
    end

    alias_method :total_entries, :total_count

    # Returns whether or not the current page is the first page.
    #
    # @example
    #   CommentIndex.paginate(page: 1).first_page?
    #   # => true
    #
    #   CommentIndex.paginate(page: 2).first_page?
    #   # => false
    #
    # @return [Boolean] Returns true if the current page is the
    #   first page or false otherwise

    def first_page?
      current_page == 1
    end

    # Returns whether or not the current page is the last page.
    #
    # @example
    #   CommentIndex.paginate(page: 100).last_page?
    #   # => true
    #
    #   CommentIndex.paginate(page: 1).last_page?
    #   # => false
    #
    # @return [Boolean] Returns true if the current page is the
    #   last page or false otherwise

    def last_page?
      current_page == total_pages
    end

    # Returns whether or not the current page is out of range,
    # ie. smaller than 1 or larger than #total_pages
    #
    # @example
    #   CommentIndex.paginate(page: 1_000_000).out_of_range?
    #   # => true
    #
    #   CommentIndex.paginate(page: 1).out_of_range?
    #   # => false
    #
    # @return [Boolean] Returns true if the current page is out
    #   of range

    def out_of_range?
      current_page < 1 || current_page > total_pages
    end

    # Returns the current page number, useful for pagination.
    #
    # @example
    #   CommentIndex.search("hello world").paginate(page: 10).current_page
    #   # => 10
    #
    # @return [Fixnum] The current page number

    def current_page
      1 + (criteria.offset_value_with_default / criteria.limit_value_with_default)
    end

    # Returns the number of total pages for the current pagination settings, ie
    # per page/limit settings.
    #
    # @example
    #   CommentIndex.search("hello world").paginate(per_page: 60).total_pages
    #   # => 5
    #
    # @return [Fixnum] The total number of pages

    def total_pages
      [(total_count.to_f / criteria.limit_value_with_default).ceil, 1].max
    end

    # Returns the previous page number or nil if no previous page exists, ie if
    # the current page is the first page.
    #
    # @example
    #   CommentIndex.search("hello world").paginate(page: 2).previous_page
    #   # => 1
    #
    #   CommentIndex.search("hello world").paginate(page: 1).previous_page
    #   # => nil
    #
    # @return [Fixnum, nil] The previous page number

    def previous_page
      return nil if current_page <= 1
      return total_pages if current_page > total_pages

      current_page - 1
    end

    alias_method :prev_page, :previous_page

    # Returns the next page number or nil if there is no next page, ie the
    # current page is the last page.
    #
    # @example
    #   CommentIndex.search("hello world").paginate(page: 2).next_page
    #   # => 3
    #
    # @return [Fixnum, nil] The next page number

    def next_page
      return nil if current_page >= total_pages
      return 1 if current_page < 1

      current_page + 1
    end

    # Returns the results, ie hits, wrapped in a SearchFlip::Result object
    # which basically is a Hashie::Mash. Check out the Hashie docs for further
    # details.
    #
    # @example
    #   CommentIndex.search("hello world").results
    #   # => [#<SearchFlip::Result ...>, ...]
    #
    # @return [Array] An array of results

    def results
      @results ||= hits["hits"].map do |hit|
        raw_result = hit["_source"].dup
        raw_result["_hit"] = hit.dup.tap { |obj| obj.delete("_source") }
        raw_result
      end
    end

    # Returns the named sugggetion, if a name is specified or alle suggestions.
    #
    # @example
    #   query = CommentIndex.suggest(:suggestion, text: "helo", term: { field: "message" })
    #   query.suggestions # => {"suggestion"=>[{"text"=>...}, ...]}
    #
    # @example Named suggestions
    #   query = CommentIndex.suggest(:suggestion, text: "helo", term: { field: "message" })
    #   query.suggestions(:sugestion).first["text"] # => "hello"
    #
    # @return [Hash, Array] The named suggestion or all suggestions

    def suggestions(name = nil)
      if name
        response["suggest"][name.to_s].first["options"]
      else
        response["suggest"]
      end
    end

    # Returns the hits returned by Elasticsearch.
    #
    # @example
    #   CommentIndex.search("hello world").hits
    #   # => {"total"=>3, "max_score"=>2.34, "hits"=>[{...}, ...]}
    #
    # @return [Hash] The hits returned by Elasticsearch

    def hits
      response["hits"]
    end

    # Returns the scroll id returned by Elasticsearch, that can be used in the
    # following request to fetch the next batch of records.
    #
    # @example
    #   CommentIndex.scroll(timeout: "1m").scroll_id #=> "cXVlcnlUaGVuRmV0Y2..."
    #
    # @return [String] The scroll id returned by Elasticsearch

    def scroll_id
      response["_scroll_id"]
    end

    # Returns the database records, usually ActiveRecord objects, depending on
    # the ORM you're using. The records are sorted using the order returned by
    # Elasticsearch.
    #
    # @example
    #   CommentIndex.search("hello world").records # => [#<Comment ...>, ...]
    #
    # @return [Array] An array of database records

    def records
      @records ||= begin
        sort_map = ids.each_with_index.each_with_object({}) { |(id, index), hash| hash[id.to_s] = index }

        scope.to_a.sort_by { |record| sort_map[criteria.target.record_id(record).to_s] }
      end
    end

    # Builds and returns a scope for the array of ids in the current result set
    # returned by Elasticsearch, including the eager load, preload and includes
    # associations, if specified. A scope is eg an ActiveRecord::Relation,
    # depending on the ORM you're using.
    #
    # @example
    #   CommentIndex.preload(:user).scope # => #<Comment::ActiveRecord_Criteria:0x0...>
    #
    # @return The scope for the array of ids in the current result set

    def scope
      res = criteria.target.fetch_records(ids)

      res = res.includes(*criteria.includes_values) if criteria.includes_values
      res = res.eager_load(*criteria.eager_load_values) if criteria.eager_load_values
      res = res.preload(*criteria.preload_values) if criteria.preload_values

      res
    end

    # Returns the array of ids returned by Elasticsearch for the current result
    # set, ie the ids listed in the hits section of the response.
    #
    # @example
    #   CommentIndex.match_all.ids # => [20341, 12942, ...]
    #
    # @return The array of ids in the current result set

    def ids
      @ids ||= hits["hits"].map { |hit| hit["_id"] }
    end

    def_delegators :ids, :size, :count, :length

    # Returns the response time in milliseconds of Elasticsearch specified in
    # the took info of the response.
    #
    # @example
    #   CommentIndex.match_all.took # => 6
    #
    # @return [Fixnum] The Elasticsearch response time in milliseconds

    def took
      response["took"]
    end

    # Returns a single or all aggregations returned by Elasticsearch, depending
    # on whether or not a name is specified. If no name is specified, the raw
    # aggregation hash is simply returned. Contrary, if a name is specified,
    # only this aggregation is returned. Moreover, if a name is specified and
    # the aggregation includes a buckets section, a post-processed aggregation
    # hash is returned.
    #
    # @example All aggregations
    #   CommentIndex.aggregate(:user_id).aggregations
    #   # => {"user_id"=>{..., "buckets"=>[{"key"=>4922, "doc_count"=>1129}, ...]}
    #
    # @example Specific and post-processed aggregations
    #   CommentIndex.aggregate(:user_id).aggregations(:user_id)
    #   # => {4922=>1129, ...}
    #
    # @return [Hash] Specific or all aggregations returned by Elasticsearch

    def aggregations(name = nil)
      return response["aggregations"] || {} unless name

      @aggregations ||= {}

      key = name.to_s

      return @aggregations[key] if @aggregations.key?(key)

      @aggregations[key] =
        if response["aggregations"].nil? || response["aggregations"][key].nil?
          Result.new
        elsif response["aggregations"][key]["buckets"].is_a?(Array)
          response["aggregations"][key]["buckets"].each_with_object(Result.new) { |bucket, hash| hash[bucket["key"]] = bucket }
        elsif response["aggregations"][key]["buckets"].is_a?(Hash)
          response["aggregations"][key]["buckets"]
        else
          response["aggregations"][key]
        end
    end
  end
end
