module Martyr
  module Schema
    class MainFactDefinition

      attr_reader :cube, :scope, :dimension_associations, :metric_definitions, :rollup_definitions
      delegate :dimension_definitions, to: :cube

      alias_method :dimensions, :dimension_associations
      alias_method :metrics, :metric_definitions
      alias_method :rollups, :rollup_definitions

      delegate :supports_metric?, to: :metric_definitions
      delegate :supports_dimension?, to: :dimension_associations

      # = DSL

      delegate :has_dimension_level, :find_dimension, to: :dimension_associations
      delegate :find_metric, :has_count_metric, :has_min_metric, :has_max_metric, :has_sum_metric, :has_custom_metric, to: :metric_definitions
      delegate :define_rollup, to: :rollup_definitions

      # @param cube [Martyr::Cube]
      def initialize(cube)
        @cube = cube
        @dimension_associations = DimensionAssociationCollection.new(dimension_definitions)
        @metric_definitions ||= Schema::MetricDefinitionCollection.new
        @rollup_definitions ||= Schema::RollupDefinitionCollection.new
      end

      def supports_dimension_level?(dimension_name, level_name)
        dimension = dimension_associations[dimension_name]
        return false unless dimension

        lowest_supported_level_i = dimension.lowest_level.to_i
        considered_level_i = dimension_definitions.find_dimension(dimension_name).find_level(level_name).to_i
        considered_level_i >= lowest_supported_level_i
      end

      def name
        'main'
      end

      def main_query(&scope)
        @scope = scope
      end

      # @return [Runtime::MainFactScope]
      def build
        Runtime::MainFactScope.new(self)
      end
    end
  end
end