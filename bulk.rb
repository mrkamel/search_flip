
require "rest-client"

module ElasticSearch
  class Bulk
    attr_accessor :url, :count, :callback

    def initialize(url, count = 1_000, callback)
      self.url = url
      self.count = count
      self.callback = callback

      init

      yield self

      upload if @num > 0
    end

    def init
      @payload = ""
      @num = 0
    end

    def upload
      response = RestClient.put(url, @payload)

      if callback
        JSON.parse(response)["items"].each_with_index do |response, index|
          callback.call response
        end
      end

      init
    end

    def index(id, json)
      @payload << { :index => { :_id => id } }.to_json
      @payload << "\n"
      @payload << json
      @payload << "\n"

      @num += 1

      upload if @num >= count
    end
  end
end

