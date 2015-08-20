module Martyr
  module ChildrenDelegator
    extend ActiveSupport::Concern


    module ClassMethods

      def each_child_delegator(*method_names, to:)
        method_names.each do |method_name|
          define_method(method_name) do |*args|
            send(to).each do |obj|
              obj.send(method_name, *args)
            end
          end
        end
      end

    end
  end
end