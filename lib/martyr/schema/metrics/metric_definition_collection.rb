module Martyr
  module Schema
    class MetricDefinitionCollection < HashWithIndifferentAccess
      include Martyr::Registrable

      def add_count_metric(name, on: name, rollup: :sum)
        register BuiltInMetric.new name: name, column: on, aggregate_function: :count, rollup_function: rollup
      end

      def add_min_metric(name, on: name)
        register BuiltInMetric.new name: name, column: on, aggregate_function: :min, rollup_function: :min
      end

      def add_max_metric(name, on: name)
        register BuiltInMetric.new name: name, column: on, aggregate_function: :max, rollup_function: :max
      end

      def add_sum_metric(name, on: name)
        register BuiltInMetric.new name: name, column: on, aggregate_function: :sum, rollup_function: :sum
      end

      def add_custom_metric(name, block, rollup: :sum)
        register CustomMetric.new name: name, block: block, rollup_function: rollup
      end

    end
  end
end