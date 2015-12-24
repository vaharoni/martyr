module Martyr
  module Runtime
    class WhereOperatorForMetric < BaseOperator

      attr_reader :metric_name
      alias_method :add_where, :operate

      def initialize(metric_name, &block)
        super(&block)
        @metric_name = metric_name
      end

      private

      def handle_outer(wrapper)
        wrapper.add_to_where(*operation_args)
      end

      def supported_for?(fact_scope)
        fact_scope.supports_metric?(metric_name)
      end

    end
  end
end
