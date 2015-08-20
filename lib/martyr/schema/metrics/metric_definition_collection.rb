module Martyr
  module Schema
    class MetricDefinitionCollection < HashWithIndifferentAccess
      include Martyr::Registrable

      alias_method :find_metric, :find_or_error
      alias_method :supports_metric?, :has_key?

      def has_sum_metric(name, statement = name, fact_alias: name)
        register BuiltInMetric.new name: name, statement: statement, fact_alias: fact_alias, rollup_function: :sum
      end

      def has_min_metric(name, statement = name, fact_alias: name)
        register BuiltInMetric.new name: name, statement: statement, fact_alias: fact_alias, rollup_function: :min
      end

      def has_max_metric(name, statement = name, fact_alias: name)
        register BuiltInMetric.new name: name, statement: statement, fact_alias: fact_alias, rollup_function: :max
      end

      def has_custom_metric(name, block, rollup: :sum)
        register CustomMetric.new name: name, block: block, rollup_function: rollup
      end

    end
  end
end