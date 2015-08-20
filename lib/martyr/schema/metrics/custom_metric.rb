module Martyr
  module Schema
    class CustomMetric < BaseMetric

      attr_accessor :block

      def build_slice(**slice_definition)
        raise Runtime::Error.new("Custom metrics cannot be sliced: attempted on metric `#{name}`")
      end

      # @param fact_scopes [Runtime::FactScopeCollection]
      def add_to_select(fact_scopes)
        # no-op
      end

    end
  end
end