module SearchFlip
  # The SearchFlip::Sortable mixin provides the chainable #highlight method to
  # use elasticsearch highlighting

  module Highlightable
    def self.included(base)
      base.class_eval do
        attr_accessor :highlight_values
      end
    end

    # Adds highlighting of the given fields to the request.
    #
    # @example
    #   CommentIndex.highlight([:title, :message])
    #   CommentIndex.highlight(:title).highlight(:description)
    #   CommentIndex.highlight(:title, require_field_match: false)
    #   CommentIndex.highlight(title: { type: "fvh" })
    #
    # @example
    #   query = CommentIndex.highlight(:title).search("hello")
    #   query.results[0].highlight.title # => "<em>hello</em> world"
    #
    # @param fields [Hash, Array, String, Symbol] The fields to highligt.
    #   Supports raw Elasticsearch values by passing a Hash.
    #
    # @param options [Hash] Extra highlighting options. Check out the Elasticsearch
    #   docs for further details.
    #
    # @return [SearchFlip::Criteria] A new criteria including the highlighting

    def highlight(fields, options = {})
      fresh.tap do |criteria|
        criteria.highlight_values = (criteria.highlight_values || {}).merge(options)

        hash =
          if fields.is_a?(Hash)
            fields
          elsif fields.is_a?(Array)
            fields.each_with_object({}) { |field, h| h[field] = {} }
          else
            { fields => {} }
          end

        criteria.highlight_values[:fields] = (criteria.highlight_values[:fields] || {}).merge(hash)
      end
    end
  end
end
