module Martyr
  module Schema
    class MetricDefinitionCollection < HashWithIndifferentAccess
      include Martyr::Registrable
      include Martyr::Translations

      attr_reader :cube, :dependency_inferrer, :standardizer
      delegate :cube_name, to: :cube

      alias_method :find_metric, :find_or_error

      def initialize(cube)
        super()
        @cube = cube
        @dependency_inferrer = cube.metric_dependency_inferrer
        @standardizer = Martyr::MetricIdStandardizer.new(cube_name)
      end

      def supports_metric?(metric_name)
        has_key? second_element_from_id(metric_name, fallback: true)
      end

      # @see register_built_in_metric
      def has_sum_metric(*args)
        register_built_in_metric(:sum, *args)
      end

      # @see register_built_in_metric
      def has_min_metric(*args)
        register_built_in_metric(:min, *args)
      end

      # @see register_built_in_metric
      def has_max_metric(*args)
        register_built_in_metric(:max, *args)
      end

      # @param level [String] The level ID on which to perform the distinct count. The level must be connected to the
      #   fact with has_dimension_level.
      def has_count_distinct_metric(name, level:, fact_alias: name, typecast: :to_i, sort: Sorter.identity, fact_grain: [])
        level_object = cube.supported_dimension_definitions.find_level_definition(level)
        register CountDistinctMetric.new cube_name: cube_name, name: name, fact_alias: fact_alias,
            typecast: typecast, sort: sort, level: level_object, fact_grain: Array.wrap(fact_grain)
      end

      def has_custom_metric(name, block, rollup: :sum, sort: Sorter.identity, depends_on: [], fact_grain: [])
        inferrer = dependency_inferrer.infer_from_block(depends_on:
            standardizer.standardize(depends_on), fact_grain: fact_grain, &block)

        register CustomMetric.new cube_name: cube_name, name: name, block: block, rollup_function: rollup, sort: sort,
            depends_on: inferrer.depends_on, fact_grain: inferrer.fact_grain
      end

      def has_custom_rollup(name, block, default: nil, sort: Sorter.identity, depends_on: [], fact_grain: [])
        inferrer = dependency_inferrer.infer_from_block(depends_on:
            standardizer.standardize(depends_on), fact_grain: fact_grain, &block)

        register CustomRollup.new cube_name: cube_name, name: name, block: block, default: default, sort: sort,
          depends_on: inferrer.depends_on, fact_grain: inferrer.fact_grain
      end

      private

      def register(metric)
        super
        dependency_inferrer.add_metric(metric)
        metric
      end

      def register_built_in_metric(rollup_function, name, statement, fact_alias: name, typecast: :to_i, sort: Sorter.identity, fact_grain: [])
        register BuiltInMetric.new cube_name: cube_name, name: name, statement: statement, fact_alias: fact_alias,
          rollup_function: rollup_function, typecast: typecast, sort: sort, fact_grain: Array.wrap(fact_grain)
      end

    end
  end
end
