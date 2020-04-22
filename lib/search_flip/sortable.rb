module SearchFlip
  # The SearchFlip::Sortable mixin provides the chainable methods #sort as
  # well as #resort

  module Sortable
    def self.included(base)
      base.class_eval do
        attr_accessor :sort_values

        alias_method :order, :sort
      end
    end

    # Specify the sort order you want Elasticsearch to use for sorting the
    # results. When you call this multiple times, the sort orders are appended
    # to the already existing ones. The sort arguments get passed to
    # Elasticsearch without modifications, such that you can use sort by
    # script, etc here as well.
    #
    # @example Default usage
    #   CommentIndex.sort(:user_id, :id)
    #
    #   # Same as
    #
    #   CommentIndex.sort(:user_id).sort(:id)
    #
    # @example Default hash usage
    #   CommentIndex.sort(user_id: "asc").sort(id: "desc")
    #
    #   # Same as
    #
    #   CommentIndex.sort({ user_id: "asc" }, { id: "desc" })
    #
    # @example Sort by native script
    #   CommentIndex.sort("_script" => "sort_script", lang: "native", order: "asc", type: "number")
    #
    # @param args The sort values that get passed to Elasticsearch
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def sort(*args)
      fresh.tap do |criteria|
        criteria.sort_values = (sort_values || []) + args
      end
    end

    # Specify the sort order you want Elasticsearch to use for sorting the
    # results with already existing sort orders being removed.
    #
    # @example
    #   CommentIndex.sort(user_id: "asc").resort(id: "desc")
    #
    #   # Same as
    #
    #   CommentIndex.sort(id: "desc")
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria
    #
    # @see #sort See #sort for more details

    def resort(*args)
      fresh.tap do |criteria|
        criteria.sort_values = args
      end
    end

    alias_method :reorder, :resort
  end
end
