module SearchFlip
  # The SearchFlip::Sortable mixin provides the chainable #source method to
  # use elasticsearch source filtering

  module Sourceable
    def self.included(base)
      base.class_eval do
        attr_accessor :source_value
      end
    end

    # Use to specify which fields of the source document you want Elasticsearch
    # to return for each matching result.
    #
    # @example
    #   CommentIndex.source([:id, :message]).search("hello world")
    #   CommentIndex.source(exclude: "description")
    #   CommentIndex.source(false)
    #
    # @param value Pass any allowed value to restrict the returned source
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def source(value)
      fresh.tap do |criteria|
        criteria.source_value = value
      end
    end
  end
end
