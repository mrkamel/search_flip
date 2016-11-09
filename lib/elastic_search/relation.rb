
module ElasticSearch
  class Relation
    extend Forwardable

    include ElasticSearch::FilterableRelation
    include ElasticSearch::PostFilterableRelation
    include ElasticSearch::AggregatableRelation
    include ElasticSearch::FacetableRelation

    attr_accessor :target, :profile_value, :source_value, :sort_values, :offset_value, :limit_value, :query_value, :includes_values, :eager_load_values, :preload_values, :failsafe_value, :scroll_args

    def initialize(options = {})
      options.each do |key, value|
        self.send "#{key}=", value
      end

      self.offset_value ||= 0
      self.limit_value ||= 30
      self.failsafe_value ||= false
    end

    def request
      res = {}

      if query_value.present? && filter_values
        res[:query] = { :filtered => { :query => { :query_string => query_value }, :filter => filter_values.size > 1 ? { :and => filter_values } : filter_values.first } }
      elsif query_value.present?
        res[:query] = { :query_string => query_value }
      elsif filter_values.present?
        res[:query] = { :filtered => { :filter => filter_values.size > 1 ? { :and => filter_values } : filter_values.first } }
      end

      res.update :from => offset_value, :size => limit_value

      res[:sort] = sort_values if sort_values
      res[:aggregations] = aggregation_values if aggregation_values
      res[:facets] = facet_values if facet_values
      res[:post_filter] = post_filter_values.size > 1 ? { :and => post_filter_values } : post_filter_values.first if post_filter_values
      res[:_source] = source_value unless source_value.nil?
      res[:profile] = true if profile_value

      res
    end

    def profile!(value)
      clear_cache!

      self.profile_value = value
      self
    end

    def profile(value)
      dup.tap do |relation|
        relation.profile!(value)
      end
    end

    def scroll!(id = nil, timeout = "1m")
      clear_cache!

      self.scroll_args = { :id => id, :timeout => timeout }
      self
    end

    def scroll(*args)
      dup.tap do |relation|
        relation.scroll!(*args)
      end
    end

    def delete
      RestClient::Request.execute :method => :delete, :url => "#{target.type_url}/_query", :payload => JSON.generate(request.except(:from, :size))

      target.refresh if ElasticSearch::Config[:environment] == "test"
    end

    def source!(value)
      clear_cache!

      self.source_value = value
      self
    end

    def source(value)
      dup.tap do |relation|
        relation.source!(value)
      end
    end

    def includes!(*args)
      clear_cache!

      self.includes_values = (includes_values || []) + args
      self
    end

    def includes(*args)
      dup.tap do |relation|
        relation.includes!(*args)
      end
    end

    def eager_load!(*args)
      clear_cache!

      self.eager_load_values = (eager_load_values || []) + args
      self
    end

    def eager_load(*args)
      dup.tap do |relation|
        relation.eager_load!(*args)
      end
    end

    def preload!(*args)
      clear_cache!

      self.preload_values = (preload_values || []) + args
      self
    end

    def preload(*args)
      dup.tap do |relation|
        relation.preload!(*args)
      end
    end

    def sort!(*args)
      clear_cache!

      self.sort_values = args
      self
    end

    def order!(*args)
      sort!(*args)
    end

    def sort(*args)
      dup.tap do |relation|
        relation.sort!(*args)
      end
    end

    def order(*args)
      sort(*args)
    end

    def offset!(n)
      clear_cache!

      self.offset_value = n.to_i
      self
    end

    def offset(n)
      dup.tap do |relation|
        relation.offset!(n)
      end
    end

    def limit!(n)
      clear_cache!

      self.limit_value = n.to_i
      self
    end

    def limit(n)
      dup.tap do |relation|
        relation.limit! n
      end
    end

    def paginate!(options = {})
      page = [(options[:page] || 1).to_i, 1].max
      per_page = (options[:per_page] || 30).to_i

      offset!((page - 1) * per_page).limit!(per_page)
    end

    def paginate(options = {})
      dup.tap do |relation|
        relation.paginate!(options)
      end
    end

    def query!(q, options = {})
      clear_cache!

      if q.present?
        self.query_value = { :default_operator => :AND }.merge(options).merge(:query => q)
      end

      self
    end

    def search!(*args)
      query!(*args)
    end

    def query(q, options = {})
      dup.tap do |relation|
        relation.query! q, options
      end
    end

    def search(*args)
      query(*args)
    end

    def find_in_batches(options = {})
      return enum_for(:find_in_batches, options) unless block_given?

      batch_size = options[:batch_size] || 1_000

      relation = limit(batch_size).scroll

      while records = relation.records.presence
        yield records

        relation = relation.scroll(relation.scroll_id)
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

    def response
      @response ||= begin
        if scroll_args && scroll_args[:id]
          if ElasticSearch.version >= "2"
            ElasticSearch::Response.new self, JSON.parse(RestClient.post("#{target.base_url}/_search/scroll", JSON.generate(:scroll => scroll_args[:timeout], :scroll_id => scroll_args[:id])))
          else
            ElasticSearch::Response.new self, JSON.parse(RestClient.post("#{target.base_url}/_search/scroll?scroll=#{scroll_args[:timeout]}", scroll_args[:id]))
          end
        elsif scroll_args
          ElasticSearch::Response.new self, JSON.parse(RestClient.post("#{target.type_url}/_search?scroll=#{scroll_args[:timeout]}", JSON.generate(request)))
        else
          ElasticSearch::Response.new self, JSON.parse(RestClient.post("#{target.type_url}/_search", JSON.generate(request)))
        end
      rescue RestClient::BadRequest, RestClient::InternalServerError, RestClient::ServiceUnavailable, Errno::ECONNREFUSED => e
        raise e unless failsafe_value

        ElasticSearch::Response.new self, "took" => 0, "hits" => { "total" => 0, "hits" => [] }
      end
    end

    def failsafe!(value)
      clear_cache!

      self.failsafe_value = value
      self
    end

    def failsafe(value)
      dup.tap do |relation|
        relation.failsafe! value
      end
    end

    def clear_cache!
      @response = nil
    end

    def fresh
      dup.tap(&:clear_cache!)
    end

    def respond_to?(name, *args)
      super || target.scopes.key?(name.to_s) || target.respond_to?(name, *args)
    end

    def method_missing(name, *args, &block)
      if target.scopes.key?(name.to_s)
        instance_exec(*args, &target.scopes[name.to_s])
      else
        super
      end
    end

    delegate [:total_entries, :current_page, :previous_page, :next_page, :total_pages, :hits, :ids, :count, :size, :length, :took, :aggregations, :facets, :scope, :results, :records, :scroll_id] => :response
  end
end

