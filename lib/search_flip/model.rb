module SearchFlip
  module Model
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def notifies_index(index)
        if respond_to?(:after_commit)
          after_commit { |record| record.destroyed? ? index.delete(record) : index.import(record) }
        else
          after_save { |record| index.import(record) }
          after_touch { |record| index.import(record) } if respond_to?(:after_touch)
          after_destroy { |record| index.delete(record) }
        end
      end
    end
  end
end
