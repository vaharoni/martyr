module Martyr
  module Schema
    class MetricDefinitionCollection < HashWithIndifferentAccess
      include Martyr::Registrable

      attr_reader :cube_name

      alias_method :find_metric, :find_or_error
      alias_method :supports_metric?, :has_key?

      def initialize(cube_name)
        super
        @cube_name = cube_name
      end

      def has_sum_metric(name, statement = name, fact_alias: name)
        register BuiltInMetric.new cube_name: cube_name, name: name, statement: statement, fact_alias: fact_alias, rollup_function: :sum
      end

      def has_min_metric(name, statement = name, fact_alias: name)
        register BuiltInMetric.new cube_name: cube_name, name: name, statement: statement, fact_alias: fact_alias, rollup_function: :min
      end

      def has_max_metric(name, statement = name, fact_alias: name)
        register BuiltInMetric.new cube_name: cube_name, name: name, statement: statement, fact_alias: fact_alias, rollup_function: :max
      end

      def has_custom_metric(name, block, rollup: :sum)
        register CustomMetric.new cube_name: cube_name, name: name, block: block, rollup_function: rollup
      end

    end
  end
end