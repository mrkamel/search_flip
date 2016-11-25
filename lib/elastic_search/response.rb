
module ElasticSearch
  class Response
    attr_accessor :relation, :response

    def initialize(relation, response)
      self.relation = relation
      self.response = response
    end

    def raw_response
      response
    end

    def total_entries
      hits["total"]
    end

    def current_page
      1 + (relation.offset_value / relation.limit_value.to_f).ceil
    end

    def total_pages
      (total_entries / relation.limit_value.to_f).ceil
    end

    def previous_page
      return nil if total_pages.zero?
      return nil if current_page <= 1
      return total_pages if current_page > total_pages

      current_page - 1
    end

    def next_page
      return nil if total_pages.zero?
      return nil if current_page >= total_pages
      return 1 if current_page < 1

      return current_page + 1
    end

    def results
      @results ||= hits["hits"].collect { |hit| Result.new hit["_source"] }
    end

    def hits
      response["hits"]
    end

    def scroll_id
      response["_scroll_id"]
    end

    def records(options = {})
      @records ||= begin
        sort_map = ids.each_with_index.each_with_object({}) { |(id, index), hash| hash[id.to_s] = index }

        scope.sort_by { |record| sort_map[record.id.to_s] }
      end
    end

    def scope
      res = relation.target.model.where(:id => ids)

      res = res.includes(*relation.includes_values) if relation.includes_values
      res = res.eager_load(*relation.eager_load_values) if relation.eager_load_values
      res = res.preload(*relation.preload_values) if relation.preload_values

      res
    end

    def ids
      @ids ||= hits["hits"].collect { |hit| hit["_id"] }
    end

    delegate :size, :count, :length, :to => :ids

    def took
      response["took"]
    end

    def aggregations(name = nil)
      return response["aggregations"] || {} unless name

      @aggregations ||= Hash.new do |cache, key|
        cache[key] =
          if response["aggregations"].blank? || response["aggregations"][key].blank?
            Hashie::Mash.new
          elsif response["aggregations"][key]["buckets"].is_a?(Array)
            response["aggregations"][key]["buckets"].each_with_object({}) { |bucket, hash| hash[bucket["key"]] = Hashie::Mash.new(bucket) }
          elsif response["aggregations"][key]["buckets"].is_a?(Hash)
            Hashie::Mash.new response["aggregations"][key]["buckets"]
          else
            Hashie::Mash.new response["aggregations"][key]
          end
      end

      @aggregations[name.to_s]
    end
  end
end

