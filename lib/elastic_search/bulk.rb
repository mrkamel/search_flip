
module ElasticSearch
  # @api private
  #
  # The ElasticSearch::Bulk class implements the bulk support, ie it collects
  # single requests and emits batches of requests. Internal use only.

  class Bulk
    class Error < StandardError; end

    attr_accessor :url, :count, :options, :ignore_errors

    def initialize(url, count = 1_000, options = {})
      self.url = url
      self.count = count
      self.options = options
      self.ignore_errors = Array(options[:ignore_errors]).to_set

      init

      yield self

      upload if @num > 0
    end

    def init
      @payload = ""
      @num = 0
    end

    def upload
      response = RestClient.put(url, @payload, params: ignore_errors.blank? ? { filter_path: "errors" } : {}, content_type: "application/json")

      return if options[:raise] == false

      parsed_response = JSON.parse(response)

      return unless parsed_response["errors"]

      raise(ElasticSearch::Bulk::Error, response[0 .. 30]) if ignore_errors.blank?

      parsed_response["items"].each do |item|
        item.each do |_, _item|
          status = _item["status"]

          raise(ElasticSearch::Bulk::Error, JSON.generate(_item)) if !status.between?(200, 299) && !ignore_errors.include?(status)
        end
      end
    ensure
      init
    end

    def index(id, json, options = {})
      perform :index, id, json, options
    end

    def import(*args)
      index(*args)
    end

    def create(id, json, options = {})
      perform :create, id, json, options
    end

    def update(id, json, options = {})
      perform :update, id, json, options
    end

    def delete(id, options = {})
      perform :delete, id, nil, options
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

