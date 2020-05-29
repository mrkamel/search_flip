module SearchFlip
  # The SearchFlip::Aggregation class puts together everything
  # required to use the Elasticsearch aggregation framework via mixins and
  # adds a method to convert it to a hash format to be used in the request.

  class Aggregation
    include Filterable
    include Aggregatable
    include Paginatable
    include Highlightable
    include Explainable
    include Sourceable
    include Sortable
    include Customable

    attr_reader :target

    def initialize(target:)
      @target = target
    end

    # @api private
    #
    # Converts the aggregation to a hash format that can be used in the request.
    #
    # @return [Hash] A hash version of the aggregation

    def to_hash
      res = {}
      res[:aggregations] = aggregation_values if aggregation_values

      if must_values || must_not_values || filter_values
        if target.connection.version.to_i >= 2
          res[:filter] = {
            bool: {}
              .merge(must_values ? { must: must_values } : {})
              .merge(must_not_values ? { must_not: must_not_values } : {})
              .merge(filter_values ? { filter: filter_values } : {})
          }
        else
          filters = (filter_values || []) + (must_not_values || []).map { |must_not_value| { not: must_not_value } }
          queries = must_values ? { must: must_values } : {}
          filters_and_queries = filters + (queries.size > 0 ? [bool: queries] : [])

          res[:filter] = filters_and_queries.size > 1 ? { and: filters_and_queries } : filters_and_queries.first
        end
      end

      res.update(from: offset_value_with_default, size: limit_value_with_default) if offset_value || limit_value

      res[:explain] = explain_value unless explain_value.nil?
      res[:highlight] = highlight_values if highlight_values
      res[:sort] = sort_values if sort_values
      res[:_source] = source_value unless source_value.nil?

      res.update(custom_value) if custom_value

      res
    end

    # @api private
    #
    # Merges a criteria into the aggregation.
    #
    # @param other [SearchFlip::Criteria] The criteria to merge in
    #
    # @return [SearchFlip::Aggregation] A fresh aggregation including the merged criteria

    def merge(other)
      other = other.criteria

      fresh.tap do |aggregation|
        unsupported_methods = [
          :profile_value, :failsafe_value, :terminate_after_value, :timeout_value, :scroll_args,
          :suggest_values, :includes_values, :preload_values, :eager_load_values, :post_must_values,
          :post_must_not_values, :post_filter_values, :preference_value, :search_type_value,
          :routing_value
        ]

        unsupported_methods.each do |unsupported_method|
          unless other.send(unsupported_method).nil?
            raise(SearchFlip::NotSupportedError, "Using #{unsupported_method} within aggregations is not supported")
          end
        end

        aggregation.source_value = other.source_value if other.source_value
        aggregation.offset_value = other.offset_value if other.offset_value
        aggregation.limit_value = other.limit_value if other.limit_value
        aggregation.scroll_args = other.scroll_args if other.scroll_args
        aggregation.explain_value = other.explain_value unless other.explain_value.nil?

        aggregation.sort_values = (aggregation.sort_values || []) + other.sort_values if other.sort_values
        aggregation.must_values = (aggregation.must_values || []) + other.must_values if other.must_values
        aggregation.must_not_values = (aggregation.must_not_values || []) + other.must_not_values if other.must_not_values
        aggregation.filter_values = (aggregation.filter_values || []) + other.filter_values if other.filter_values

        aggregation.highlight_values = (aggregation.highlight_values || {}).merge(other.highlight_values) if other.highlight_values
        aggregation.custom_value = (aggregation.custom_value || {}).merge(other.custom_value) if other.custom_value
        aggregation.aggregation_values = (aggregation.aggregation_values || {}).merge(other.aggregation_values) if other.aggregation_values
      end
    end

    def respond_to_missing?(name, *args)
      target.respond_to?(name, *args)
    end

    ruby2_keywords def method_missing(name, *args, &block)
      if target.respond_to?(name)
        merge(target.send(name, *args, &block))
      else
        super
      end
    end

    ruby2_keywords :method_missing

    # @api private
    #
    # Simply dups the object for api compatability.
    #
    # @return [SearchFlip::Aggregation] The dupped object

    def fresh
      dup
    end
  end
end
