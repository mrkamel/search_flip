
module ElasticSearch
  # The ElasticSearch::Relation class serves the purpose of chaining various
  # filtering and aggregation methods. Each chainable method creates a new
  # relation object until a method is called that finally sends the respective
  # request to ElasticSearch and then the result is returned.
  #
  # @example
  #   CommentIndex.where(visible: true).sort(id: "desc").limit(1_000).records
  #   CommentIndex.range(:created_at, lt: Time.parse("2014-01-01").delete
  #   CommentIndex.search("hello world").total_entries
  #   CommentIndex.query(more_like_this: { fields: ["description"], ... })]
  #   CommentIndex.exists(:user_id).paginate(page: 1, per_page: 100)
  #   CommentIndex.sort("_doc").find_each { |comment| ... }

  class Relation
    include ElasticSearch::FilterableRelation
    include ElasticSearch::PostFilterableRelation
    include ElasticSearch::AggregatableRelation

    attr_accessor :target, :profile_value, :source_value, :sort_values, :highlight_values, :suggest_values, :offset_value, :limit_value, :query_value,
      :includes_values, :eager_load_values, :preload_values, :failsafe_value, :scroll_args

    # Creates a new ElasticSearch::Relation.
    #
    # @param attributes [Hash] Attributes to initialize the Relation with

    def initialize(attributes = {})
      attributes.each do |key, value|
        self.send "#{key}=", value
      end

      self.offset_value ||= 0
      self.limit_value ||= 30
      self.failsafe_value ||= false
    end

    # Generates the request object from the attributes specified via chaining,
    # like eg offset, limit, query, filters, aggregations, etc and returns a
    # Hash that later gets serialized as JSON.
    #
    # @return [Hash] The generated request object

    def request
      res = {}

      if query_value.present? && filter_values
        res[:query] = { :filtered => { :query => query_value, :filter => filter_values.size > 1 ? { :and => filter_values } : filter_values.first } }
      elsif query_value.present?
        res[:query] = query_value
      elsif filter_values.present?
        res[:query] = { :filtered => { :filter => filter_values.size > 1 ? { :and => filter_values } : filter_values.first } }
      end

      res.update :from => offset_value, :size => limit_value

      res[:highlight] = highlight_values if highlight_values
      res[:suggest] = suggest_values if suggest_values
      res[:sort] = sort_values if sort_values
      res[:aggregations] = aggregation_values if aggregation_values
      res[:post_filter] = post_filter_values.size > 1 ? { :and => post_filter_values } : post_filter_values.first if post_filter_values
      res[:_source] = source_value unless source_value.nil?
      res[:profile] = true if profile_value

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
    #   CommentIndex.highlight(:title).search("hello").results[0].highlight.title
    #   # => "<em>hello</em> world"
    #
    # @param fields [Hash, Array, String, Symbol] The fields to highligt.
    #   Supports raw ElasticSearch values by passing a Hash.
    #
    # @param options [Hash] Extra highlighting options. Check out the ElasticSearch
    #   docs for further details.
    #
    # @return [ElasticSearch::Relation] A new relation including the highlighting

    def highlight(fields, options = {})
      fresh.tap do |relation|
        relation.highlight_values = (relation.highlight_values || {}).merge(options)

        hash = if fields.is_a?(Hash)
          fields
        elsif fields.is_a?(Array)
          fields.each_with_object({}) { |field, h| h[field] = {} }
        else
          { fields => {} }
        end

        relation.highlight_values[:fields] = (relation.highlight_values[:fields] || {}).merge(hash)
      end
    end

    def suggest(name, options = {})
      fresh.tap do |relation|
        relation.suggest_values = (relation.suggest_values || {}).merge(name => options)
      end
    end

    def profile(value)
      fresh.tap do |relation|
        relation.profile_value = value
      end
    end

    def scroll(id: nil, timeout: "1m")
      fresh.tap do |relation|
        relation.scroll_args = { :id => id, :timeout => timeout }
      end
    end

    def delete
      RestClient::Request.execute :method => :delete, :url => "#{target.type_url}/_query", :payload => JSON.generate(request.except(:from, :size)), :headers => { :content_type => "application/json" }

      target.refresh if ElasticSearch::Config[:environment] == "test"
    end

    def source(value)
      fresh.tap do |relation|
        relation.source_value = value
      end
    end

    def includes(*args)
      fresh.tap do |relation|
        relation.includes_values = (includes_values || []) + args
      end
    end

    def eager_load(*args)
      fresh.tap do |relation|
        relation.eager_load_values = (eager_load_values || []) + args
      end
    end

    def preload(*args)
      fresh.tap do |relation|
        relation.preload_values = (preload_values || []) + args
      end
    end

    def sort(*args)
      fresh.tap do |relation|
        relation.sort_values = (sort_values || []) + args
      end
    end

    alias_method :order, :sort

    def resort(*args)
      fresh.tap do |relation|
        relation.sort_values = args
      end
    end

    alias_method :reorder, :resort

    def offset(n)
      fresh.tap do |relation|
        relation.offset_value = n.to_i
      end
    end

    def limit(n)
      fresh.tap do |relation|
        relation.limit_value = n.to_i
      end
    end

    def paginate(options = {})
      page = [(options[:page] || 1).to_i, 1].max
      per_page = (options[:per_page] || 30).to_i

      offset((page - 1) * per_page).limit(per_page)
    end

    def search(q, options = {})
      fresh.tap do |relation|
        relation.query_value = { :query_string => { :query => q, :default_operator => :AND }.merge(options) } if q.present?
      end
    end

    def query(q)
      fresh.tap do |relation|
        relation.query_value = q
      end
    end

    def find_in_batches(options = {})
      return enum_for(:find_in_batches, options) unless block_given?

      batch_size = options[:batch_size] || 1_000
      timeout = options[:timeout] || "1m"

      relation = limit(batch_size).scroll(timeout: timeout)

      while records = relation.records.presence
        yield records

        relation = relation.scroll(id: relation.scroll_id, timeout: timeout)
      end
    end

    def find_each(options = {})
      return enum_for(:find_each, options) unless block_given?

      find_in_batches options do |batch|
        batch.each do |record|
          yield record
        end
      end
    end

    alias_method :each, :find_each

    def response
      @response ||= begin
        if scroll_args && scroll_args[:id]
          if ElasticSearch.version.to_i >= 2
            ElasticSearch::Response.new self, JSON.parse(RestClient.post("#{target.base_url}/_search/scroll", JSON.generate(:scroll => scroll_args[:timeout], :scroll_id => scroll_args[:id]), :content_type => "application/json"))
          else
            ElasticSearch::Response.new self, JSON.parse(RestClient.post("#{target.base_url}/_search/scroll?scroll=#{scroll_args[:timeout]}", scroll_args[:id], :content_type => "application/json"))
          end
        elsif scroll_args
          ElasticSearch::Response.new self, JSON.parse(RestClient.post("#{target.type_url}/_search?scroll=#{scroll_args[:timeout]}", JSON.generate(request), :content_type => "application/json"))
        else
          ElasticSearch::Response.new self, JSON.parse(RestClient.post("#{target.type_url}/_search", JSON.generate(request), :content_type => "application/json"))
        end
      rescue RestClient::BadRequest, RestClient::InternalServerError, RestClient::ServiceUnavailable, Errno::ECONNREFUSED => e
        raise e unless failsafe_value

        ElasticSearch::Response.new self, "took" => 0, "hits" => { "total" => 0, "hits" => [] }
      end
    end

    def failsafe(value)
      fresh.tap do |relation|
        relation.failsafe_value = value
      end
    end

    def fresh
      dup.tap do |relation|
        relation.instance_variable_set(:@response, nil)
      end
    end

    def respond_to?(name, *args)
      super || target.scopes.key?(name.to_s)
    end

    def method_missing(name, *args, &block)
      if target.scopes.key?(name.to_s)
        instance_exec(*args, &target.scopes[name.to_s])
      else
        super
      end
    end

    delegate :total_entries, :current_page, :previous_page, :next_page, :total_pages, :hits, :ids, :count, :size, :length, :took, :aggregations, :suggestions,
      :scope, :results, :records, :scroll_id, :raw_response, :to => :response
  end
end

