
module ElasticSearch
  # The ElasticSearch::Bulk class implements the bulk support, ie it collects
  # single requests and emits batches of requests.
  #
  # @example
  #   ElasticSearch::Bulk.new "http://127.0.0.1:9200/index/type/_bulk" do |bulk|
  #     bulk.create record.id, JSON.generate(MyIndex.serialize(record))
  #     bulk.index record.id, JSON.generate(MyIndex.serialize(record)), version: record.version, version_type: "external"
  #     bulk.delete record.id, routing: record.user_id
  #     bulk.update record.id, JSON.generate(MyIndex.serialize(record))
  #   end

  class Bulk
    class Error < StandardError; end

    attr_accessor :url, :count, :options, :ignore_errors

    # Builds and yields a new Bulk object, ie initiates the buffer, yields,
    # sends batches of records each time the buffer is full, and sends a final
    # batch after the yielded code returns and there are still documents
    # present within the buffer.
    #
    # @example Basic use
    #   ElasticSearch::Bulk.new "http://127.0.0.1:9200/index/type/_bulk" do |bulk|
    #     # ...
    #   end
    #
    # @example Ignore certain errors
    #   ElasticSearch::Bulk.new "http://127.0.0.1:9200/index/type/_bulk", 1_000, ignore_errors: [409] do |bulk|
    #     # ...
    #   end
    #
    # @param url [String] The endpoint to send bulk requests to
    # @param count [Fixnum] The maximum number of documents per bulk request
    # @param options [Hash] Options for the bulk requests
    # @option options ignore_errors [Array, Fixnum] Errors that should be
    #   ignored. If you eg want to ignore errors resulting from conflicts,
    #   you can specify to ignore 409 here.
    # @option options raise [Boolean] If you want the bulk requests to never
    #   raise any exceptions (fire and forget), you can pass false here.
    #   Default is true.

    def initialize(url, count = 1_000, options = {})
      self.url = url
      self.count = count
      self.options = options
      self.ignore_errors = Array(options[:ignore_errors]).to_set if options[:ignore_errors]

      init

      yield self

      upload if @num > 0
    end

    # Adds an index request to the bulk batch.
    #
    # @param id [Fixnum, String] The document/record id
    # @param json [String] The json document
    # @param options [options] Options for the index request, like eg routing
    #   and versioning

    def index(id, json, options = {})
      perform :index, id, json, options
    end

    # Adds an index request to the bulk batch
    #
    # @see #index

    def import(*args)
      index(*args)
    end

    # Adds a create request to the bulk batch.
    #
    # @param id [Fixnum, String] The document/record id
    # @param json [String] The json document
    # @param options [options] Options for the index request, like eg routing
    #   and versioning

    def create(id, json, options = {})
      perform :create, id, json, options
    end

    # Adds a update request to the bulk batch.
    #
    # @param id [Fixnum, String] The document/record id
    # @param json [String] The json document
    # @param options [options] Options for the index request, like eg routing
    #   and versioning

    def update(id, json, options = {})
      perform :update, id, json, options
    end

    # Adds a delete request to the bulk batch.
    #
    # @param id [Fixnum, String] The document/record id
    # @param options [options] Options for the index request, like eg routing
    #   and versioning

    def delete(id, options = {})
      perform :delete, id, nil, options
    end

    private

    def init
      @payload = ""
      @num = 0
    end

    def upload
      response = ElasticSearch::HTTPClient.headers(accept: "application/json", content_type: "application/x-ndjson").put(url, body: @payload, params: ignore_errors ? {} : { filter_path: "errors" })

      return if options[:raise] == false

      parsed_response = response.parse

      return unless parsed_response["errors"]

      raise(ElasticSearch::Bulk::Error, response[0 .. 30]) unless ignore_errors

      parsed_response["items"].each do |item|
        item.each do |_, _item|
          status = _item["status"]

          raise(ElasticSearch::Bulk::Error, JSON.generate(_item)) if !status.between?(200, 299) && !ignore_errors.include?(status)
        end
      end
    ensure
      init
    end

    def perform(action, id, json = nil, options = {})
      @payload << JSON.generate(action => options.merge(_id: id))
      @payload << "\n"

      if json
        @payload << json
        @payload << "\n"
      end

      @num += 1

      upload if @num >= count
    end
  end
end

