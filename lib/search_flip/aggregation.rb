
module SearchFlip
  # The SearchFlip::Aggregation class puts together everything
  # required to use the Elasticsearch aggregation framework via mixins and
  # adds a method to convert it to a hash format to be used in the request.

  class Aggregation
    include SearchFlip::Filterable
    include SearchFlip::Aggregatable

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
          :profile_value, :failsafe_value, :terminate_after_value, :timeout_value, :offset_value, :limit_value,
          :scroll_args, :highlight_values, :suggest_values, :custom_value, :source_value, :sort_values,
          :includes_values, :preload_values, :eager_load_values, :post_must_values,
          :post_must_not_values, :post_filter_values, :preference_value,
          :search_type_value, :routing_value
        ]

        unsupported_methods.each do |unsupported_method|
          unless other.send(unsupported_method).nil?
            raise(SearchFlip::NotSupportedError, "Using #{unsupported_method} within aggregations is not supported")
          end
        end

        aggregation.must_values = (aggregation.must_values || []) + other.must_values if other.must_values
        aggregation.must_not_values = (aggregation.must_not_values || []) + other.must_not_values if other.must_not_values
        aggregation.filter_values = (aggregation.filter_values || []) + other.filter_values if other.filter_values

        aggregation.aggregation_values = (aggregation.aggregation_values || {}).merge(other.aggregation_values) if other.aggregation_values
      end
    end

    def respond_to_missing?(name, *args)
      target.respond_to?(name, *args)
    end

    def method_missing(name, *args, &block)
      if target.respond_to?(name)
        merge(target.send(name, *args, &block))
      else
        super
      end
    end

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

