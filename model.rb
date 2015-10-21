
require "rest-client"

module ElasticSearch
  module Model
    def self.included(base)
      base.extend ClassMethods

      base.class_attribute :elastic_search_scopes
      base.elastic_search_scopes = {}
    end

    def to_elastic_search_json
      to_json
    end

    def elastic_search_index
      RestClient.put "#{self.class.elastic_search_url}/#{id}", to_elastic_search_json

      self.class.elastic_search_refresh if Rails.env.test?
    end

    def elastic_search_delete
      self.class.elastic_search_delete id
    end

    module ClassMethods
      def elastic_search
        ElasticSearch::Relation.new :target => self
      end

      def elastic_search_type_name
        name.pluralize.underscore
      end

      def elastic_search_index_name
        ElasticSearch::Config[:index]
      end
     
      def elastic_search_refresh
        RestClient.post "#{elastic_search_base_url}/_refresh", "{}"
      end

      def elastic_search_index(options = {}, &callback) 
        ElasticSearch::Bulk.new("#{elastic_search_url}/_bulk", ElasticSearch::Config[:bulk_limit], callback) do |indexer|
          find_each do |image|
            indexer.index image.id, image.to_elastic_search_json
          end 
        end 

        elastic_search_refresh if Rails.env.test?
      end

      def elastic_search_delete(id)
        RestClient.delete "#{elastic_search_url}/#{id}"

        elastic_search_refresh if Rails.env.test?
      end

      def elastic_search_delete_all
        RestClient.delete "#{elastic_search_url}/_query?q=*:*&refresh=true"
      end

      def elastic_search_scope(name, &block)
        self.elastic_search_scopes = elastic_search_scopes.merge(name.to_s => block)
      end

      def elastic_search_url
        "#{elastic_search_base_url}/#{elastic_search_type_name}"
      end

      def elastic_search_base_url
        "#{ElasticSearch::Config[:base_url]}/#{elastic_search_index_name}"
      end
    end
  end
end

