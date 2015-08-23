module Martyr
  module Schema
    class BaseMetric
      include ActiveModel::Model

      attr_accessor :name, :rollup_function

      def build_slice
        raise NotImplementedError
      end

      # @param fact_scopes [Runtime::FactScopeCollection]
      def add_to_select(fact_scopes)
        raise NotImplementedError
      end

    end
  end
end