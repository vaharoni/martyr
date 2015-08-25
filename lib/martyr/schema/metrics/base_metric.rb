module Martyr
  module Schema
    class BaseMetric
      include ActiveModel::Model

      attr_accessor :cube_name, :name, :rollup_function

      def id
        "#{cube_name}.name"
      end

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