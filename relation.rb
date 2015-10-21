
require File.expand_path("../filterable_relation", __FILE__)
require File.expand_path("../aggregatable_relation", __FILE__)
require File.expand_path("../facetable_relation", __FILE__)
require "rest-client"

module ElasticSearch
  class Relation
    include ElasticSearch::FilterableRelation
    include ElasticSearch::AggregatableRelation
    include ElasticSearch::FacetableRelation

    attr_accessor :sort_values, :offset_value, :limit_value, :query_value, :target, :includes_values, :eager_load_values, :preload_values

    def initialize(options = {})
      options.each do |key, value|
        self.send "#{key}=", value
      end

      self.offset_value ||= 0
      self.limit_value ||= 30
    end

    def request
      res = {}

      if query_value.present? && filter_values.present?
        res[:query] = { :filtered => { :query => { :query_string => query_value }, :filter => { :and => filter_values } } }
      elsif query_value.present?
        res[:query] = { :query_string => query_value }
      elsif filter_values.present?
        res[:query] = { :filtered => { :filter => { :and => filter_values } } }
      end

      res.update :from => offset_value, :size => limit_value

      res[:sort] = sort_values if sort_values
      res[:aggregations] = aggregation_values if aggregation_values
      res[:facets] = facet_values if facet_values

      res
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

    alias_method :order!, :sort!

    def sort(*args)
      dup.tap do |relation|
        relation.sort!(*args)
      end
    end

    alias_method :order, :sort

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
        if query_value.present?
          self.query_value = query_value.merge(options).merge(:query => "(#{query_value[:query]}) (#{q})")
        else
          self.query_value = { :default_operator => :AND }.merge(options).merge(:query => q)
        end
      end

      self
    end

    alias_method :search!, :query!

    def query(q, options = {})
      dup.tap do |relation|
        relation.query! q, options
      end
    end

    alias_method :search, :query

    def find_in_batches(options = {})
      return enum_for(:find_in_batches, options) unless block_given?

      batch_size = options[:batch_size] || 1_000

      relation = sort(:id).limit(batch_size)
      current = relation.filter(:range => { :id => { :gt => options[:start] || 0 }})

      while current.ids.any?
        yield current.response.records

        break if current.ids.size < batch_size

        current = relation.filter(:range => { :id => { :gt => current.ids.max }})
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
      @response ||= ElasticSearch::Response.new(self, RestClient.post("#{ElasticSearch::Config[:base_url]}/#{target.elastic_search_index_name}/#{target.elastic_search_type_name}/_search", request.to_json))
    end

    def clear_cache!
      @response = nil
    end

    def respond_to?(name, *args)
      super || target.elastic_search_scopes.key?(name.to_s)
    end

    def method_missing(name, *args, &block)
      if target.elastic_search_scopes.key?(name.to_s)
        instance_exec(*args, &target.elastic_search_scopes[name.to_s])
      else
        super
      end
    end

    delegate :total_entries, :current_page, :previous_page, :next_page, :total_pages, :hits, :ids, :count, :size, :length, :took, :aggregations, :facets, :scope, :results, :records, :to => :response
  end
end

