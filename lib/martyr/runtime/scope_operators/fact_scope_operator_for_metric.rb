module Martyr
  module Runtime
    class FactScopeOperatorForMetric < BaseFactScopeOperator

      attr_reader :metric_name

      def initialize(metric_name, &block)
        @metric_name = metric_name
        @block = block
      end

      def supported?
        fact_scope.supports_metric?(metric_name)
      end

    end
  end
end