module SearchFlip
  # The SearchFlip::Paginatable mixin provides chainable methods to allow
  # paginating the search results

  module Paginatable
    def self.included(base)
      base.class_eval do
        attr_accessor :offset_value, :limit_value
      end
    end

    # Sets the request offset, ie SearchFlip's from parameter that is used
    # to skip results in the result set from being returned.
    #
    # @example
    #   CommentIndex.offset(100)
    #
    # @param value [Fixnum] The offset value, ie the number of results that are
    #   skipped in the result set
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def offset(value)
      fresh.tap do |criteria|
        criteria.offset_value = value.to_i
      end
    end

    # @api private
    #
    # Returns the offset value or, if not yet set,  the default limit value (0).
    #
    # @return [Fixnum] The offset value

    def offset_value_with_default
      (offset_value || 0).to_i
    end

    # Sets the request limit, ie Elasticsearch's size parameter that is used
    # to restrict the results that get returned.
    #
    # @example
    #   CommentIndex.limit(100)
    #
    # @param value [Fixnum] The limit value, ie the max number of results that
    #   should be returned
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def limit(value)
      fresh.tap do |criteria|
        criteria.limit_value = value.to_i
      end
    end

    # @api private
    #
    # Returns the limit value or, if not yet set, the default limit value (30).
    #
    # @return [Fixnum] The limit value

    def limit_value_with_default
      (limit_value || 30).to_i
    end

    # Sets pagination parameters for the criteria by using offset and limit,
    # ie Elasticsearch's from and size parameters.
    #
    # @example
    #   CommentIndex.paginate(page: 3)
    #   CommentIndex.paginate(page: 5, per_page: 60)
    #
    # @param page [#to_i] The current page
    # @param per_page [#to_i] The number of results per page
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def paginate(page: 1, per_page: 30)
      page = [page.to_i, 1].max
      per_page = per_page.to_i

      offset((page - 1) * per_page).limit(per_page)
    end

    def page(value)
      paginate(page: value, per_page: limit_value_with_default)
    end

    def per(value)
      paginate(page: 1 + (offset_value_with_default / limit_value_with_default), per_page: value)
    end
  end
end
