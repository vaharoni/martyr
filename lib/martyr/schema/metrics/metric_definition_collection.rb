module Martyr
  module Schema
    class MetricDefinitionCollection < HashWithIndifferentAccess
      include Martyr::Registrable
      include Martyr::Translations

      attr_reader :cube, :standardizer
      delegate :cube_name, to: :cube

      alias_method :find_metric, :find_or_error

      def initialize(cube)
        super()
        @cube = cube
        @standardizer = Martyr::MetricIdStandardizer.new(cube_name)
      end

      def supports_metric?(metric_name)
        has_key? second_element_from_id(metric_name, fallback: true)
      end

      def has_sum_metric(name, statement, fact_alias: name, typecast: :to_i, sort: Sorter.identity, fact_grain: [])
        register BuiltInMetric.new cube_name: cube_name, name: name, statement: statement, fact_alias: fact_alias,
            rollup_function: :sum, typecast: typecast, sort: sort, fact_grain: Array.wrap(fact_grain)
      end

      def has_min_metric(name, statement, fact_alias: name, typecast: :to_i, sort: Sorter.identity, fact_grain: [])
        register BuiltInMetric.new cube_name: cube_name, name: name, statement: statement, fact_alias: fact_alias,
            rollup_function: :min, typecast: typecast, sort: sort, fact_grain: Array.wrap(fact_grain)
      end

      def has_max_metric(name, statement, fact_alias: name, typecast: :to_i, sort: Sorter.identity, fact_grain: [])
        register BuiltInMetric.new cube_name: cube_name, name: name, statement: statement, fact_alias: fact_alias,
            rollup_function: :max, typecast: typecast, sort: sort, fact_grain: Array.wrap(fact_grain)
      end

      # @param level [String] The level ID on which to perform the distinct count. The level must be connected to the
      #   fact with has_dimension_level.
      def has_count_distinct_metric(name, level:, fact_alias: name, typecast: :to_i, sort: Sorter.identity, fact_grain: [])
        level_object = cube.supported_dimension_definitions.find_level_definition(level)
        register CountDistinctMetric.new cube_name: cube_name, name: name, fact_alias: fact_alias,
            typecast: typecast, sort: sort, level: level_object, fact_grain: Array.wrap(fact_grain)
      end

      def has_custom_metric(name, block, rollup: :sum, sort: Sorter.identity, depends_on: [], fact_grain: [])
        register CustomMetric.new cube_name: cube_name, name: name, block: block, rollup_function: rollup, sort: sort,
            depends_on: standardizer.standardize(Array.wrap(depends_on)), fact_grain: Array.wrap(fact_grain)
      end

      def has_custom_rollup(name, block, default: nil, sort: Sorter.identity, depends_on: [], fact_grain: [])
        register CustomRollup.new cube_name: cube_name, name: name, block: block, default: default, sort: sort,
            depends_on: standardizer.standardize(Array.wrap(depends_on)), fact_grain: Array.wrap(fact_grain)
      end

    end
  end
end
