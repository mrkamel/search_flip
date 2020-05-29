module SearchFlip
  # @api private
  #
  # The SearchFlip::Bulk class implements the bulk support, ie it collects
  # single requests and emits batches of requests.
  #
  # @example
  #   SearchFlip::Bulk.new "http://127.0.0.1:9200/index/type/_bulk" do |bulk|
  #     bulk.create record.id, MyIndex.serialize(record)
  #     bulk.index record.id, MyIndex.serialize(record), version: record.version, version_type: "external"
  #     bulk.delete record.id, routing: record.user_id
  #     bulk.update record.id, doc: MyIndex.serialize(record)
  #   end

  class Bulk
    class Error < StandardError; end

    attr_reader :url, :options, :ignore_errors

    # @api private
    #
    # Builds and yields a new Bulk object, ie initiates the buffer, yields,
    # sends batches of records each time the buffer is full, and sends a final
    # batch after the yielded code returns and there are still documents
    # present within the buffer.
    #
    # @example Basic use
    #   SearchFlip::Bulk.new "http://127.0.0.1:9200/index/type/_bulk" do |bulk|
    #     # ...
    #   end
    #
    # @example Ignore certain errors
    #   SearchFlip::Bulk.new "http://127.0.0.1:9200/index/type/_bulk", 1_000, ignore_errors: [409] do |bulk|
    #     # ...
    #   end
    #
    # @param url [String] The endpoint to send bulk requests to
    # @param options [Hash] Options for the bulk requests
    # @option options bulk_limit [Fixnum] The maximum number of documents per bulk
    #   request
    # @option bulk_max_mb [Fixnum] The maximum payload size in megabytes per
    #   bulk request
    # @option options ignore_errors [Array, Fixnum] Errors that should be
    #   ignored. If you eg want to ignore errors resulting from conflicts,
    #   you can specify to ignore 409 here.
    # @option options raise [Boolean] If you want the bulk requests to never
    #   raise any exceptions (fire and forget), you can pass false here.
    #   Default is true.
    # @option options http_client [SearchFlip::HTTPClient] An optional http
    #   client instance

    def initialize(url, options = {})
      @url = url
      @options = options
      @http_client = options[:http_client] || SearchFlip::HTTPClient.new
      @ignore_errors = Array(options[:ignore_errors] || []).to_set

      @bulk_limit = options[:bulk_limit] || SearchFlip::Config[:bulk_limit]
      @bulk_max_mb = options[:bulk_max_mb] || SearchFlip::Config[:bulk_max_mb]

      @bulk_max_bytes = @bulk_max_mb * 1024 * 1024

      init

      yield self

      upload if @num > 0
    end

    # @api private
    #
    # Adds an index request to the bulk batch.
    #
    # @param id [Fixnum, String] The document/record id
    # @param json [String] The json document
    # @param options [options] Options for the index request, like eg routing
    #   and versioning

    def index(id, object, options = {})
      perform(:index, id, SearchFlip::JSON.generate(object), options)
    end

    # @api private
    #
    # Adds an index request to the bulk batch
    #
    # @see #index

    ruby2_keywords def import(*args)
      index(*args)
    end

    # @api private
    #
    # Adds a create request to the bulk batch.
    #
    # @param id [Fixnum, String] The document/record id
    # @param json [String] The json document
    # @param options [options] Options for the index request, like eg routing
    #   and versioning

    def create(id, object, options = {})
      perform(:create, id, SearchFlip::JSON.generate(object), options)
    end

    # @api private
    #
    # Adds a update request to the bulk batch.
    #
    # @param id [Fixnum, String] The document/record id
    # @param json [String] The json document
    # @param options [options] Options for the index request, like eg routing
    #   and versioning

    def update(id, object, options = {})
      perform(:update, id, SearchFlip::JSON.generate(object), options)
    end

    # @api private
    #
    # Adds a delete request to the bulk batch.
    #
    # @param id [Fixnum, String] The document/record id
    # @param options [options] Options for the index request, like eg routing
    #   and versioning

    def delete(id, options = {})
      perform(:delete, id, nil, options)
    end

    private

    def init
      @payload = ""
      @num = 0
    end

    def upload
      response =
        @http_client
          .headers(accept: "application/json", content_type: "application/x-ndjson")
          .put(url, body: @payload)

      return if options[:raise] == false

      parsed_response = response.parse

      return unless parsed_response["errors"]

      parsed_response["items"].each do |item|
        item.each do |_, element|
          status = element["status"]

          next if status.between?(200, 299)
          next if ignore_errors.include?(status)

          raise SearchFlip::Bulk::Error, SearchFlip::JSON.generate(element)
        end
      end
    ensure
      init
    end

    def perform(action, id, json = nil, options = {})
      new_payload = SearchFlip::JSON.generate(action => options.merge(_id: id))
      new_payload << "\n"

      if json
        new_payload << json
        new_payload << "\n"
      end

      upload if @num > 0 && @payload.bytesize + new_payload.bytesize >= @bulk_max_bytes

      @payload << new_payload

      @num += 1

      upload if @num >= @bulk_limit || @payload.bytesize >= @bulk_max_bytes
    end
  end
end
