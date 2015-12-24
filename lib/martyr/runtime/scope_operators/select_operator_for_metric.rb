module Martyr
  module Runtime
    class SelectOperatorForMetric < BaseOperator

      attr_reader :metric_name
      attr_reader :what, :as, :data_rollup_sql

      def initialize(metric_name, &block)
        super(&block)
        @metric_name = metric_name
      end

      def add_select(what, as:, data_rollup_sql:)
        @what = what
        @as = as
        @data_rollup_sql = data_rollup_sql
      end

      private

      def handle_inner(fact_scope)
        fact_scope.decorate_scope {|scope| scope.select("#{what} AS #{as}") }
      end

      def handle_outer(wrapper)
        wrapper.add_to_select(data_rollup_sql)
      end

      def supported_for?(fact_scope)
        fact_scope.supports_metric?(metric_name)
      end

    end
  end
end
