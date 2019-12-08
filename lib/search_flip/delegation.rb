module SearchFlip
  module Delegation
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def delegate_methods(*method_names, to:)
        method_names.each do |method_name|
          code = %{
            def #{method_name}(*args, &block)
              #{to}.send(:#{method_name}, *args, &block)
            end
          }

          module_eval code
        end
      end
    end
  end
end
