module SearchFlip
  # The SearchFlip::Sortable mixin provides the chainable #custom method to
  # add arbitrary sections to the elasticsearch request

  module Customable
    def self.included(base)
      base.class_eval do
        attr_accessor :custom_value
      end
    end

    # Adds a fully custom field/section to the request, such that upcoming or
    # minor Elasticsearch features as well as other custom requirements can be
    # used without having yet specialized criteria methods.
    #
    # @note Use with caution, because using #custom will potentiall override
    #   other sections like +aggregations+, +query+, +sort+, etc if you use the
    #   the same section names.
    #
    # @example
    #   CommentIndex.custom(section: { argument: "value" }).request
    #   => {:section=>{:argument=>"value"},...}
    #
    # @param hash [Hash] The custom section that is added to the request
    #
    # @return [SearchFlip::Criteria] A newly created extended criteria

    def custom(hash)
      fresh.tap do |criteria|
        criteria.custom_value = (custom_value || {}).merge(hash)
      end
    end
  end
end
