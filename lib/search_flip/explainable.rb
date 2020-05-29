module SearchFlip
  # The SearchFlip::Sortable mixin provides the chainable #explain method to
  # control elasticsearch query explanations

  module Explainable
    def self.included(base)
      base.class_eval do
        attr_accessor :explain_value
      end
    end

    # Specifies whether or not to enable explanation for each hit on how
    # its score was computed.
    #
    # @example
    #   CommentIndex.explain(true)
    #
    # @param value [Boolean] The value for explain
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def explain(value)
      fresh.tap do |criteria|
        criteria.explain_value = value
      end
    end
  end
end
