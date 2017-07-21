
module ElasticSearch
  # The ElasticSearch::Model mixin provides means to interact with associated
  # index classes. For instance, you can notify an index about model changes
  # via callbacks, such that the index can subsequently re-index/delete the
  # respective records.

  module Model
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Notifies the index on after_save and after_destroy callbacks, such that
      # the index can re-index/delete the respective records. Works with all
      # ORMs that support after_save and after_destroy callbacks, like eg.
      # ActiveRecord, Mongoid, etc.
      #
      # @example
      #   class User < ActiveRecord::Base
      #     include ElasticSearch::Model
      #
      #     notify_index UserIndex
      #
      #     # ... is equivalent to:
      #
      #     # after_save { |user| UserIndex.import(user) }
      #     # after_destroy { |user| UserIndex.delete(user) }
      #   end

      def notify_index(index)
        after_save { |record| index.import(record) }
        after_destroy { |record| index.delete(record) }
      end
    end
  end
end

