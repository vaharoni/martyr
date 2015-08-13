module Martyr
  module Schema
    class BaseMetric
      include ActiveModel::Model

      attr_accessor :name, :rollup_function

      def build_slice(**slice_definition)
        raise NotImplementedError
      end

      # @param scopeable [#update_scope]
      def apply_on_data(scopeable)
        raise NotImplementedError
      end

    end
  end
end