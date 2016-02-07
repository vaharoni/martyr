module Martyr
  module Schema
    class MainFactDefinition < BaseFactDefinition

      delegate :dimension_definitions, to: :@cube

      delegate :supports_metric?, to: :metric_definitions
      delegate :supports_dimension?, to: :dimension_associations

      # = DSL

      delegate :has_dimension_level, :find_dimension_association, :find_level_association, to: :dimension_associations
      delegate :find_metric, :has_count_distinct_metric, :has_min_metric, :has_max_metric, :has_sum_metric,
               :has_custom_metric, :has_custom_rollup, to: :metric_definitions

      # @param cube [Martyr::Cube]
      def initialize(cube)
        @cube = cube
        @joins_by_default = true
      end

      def dimension_associations
        @dimension_associations ||= DimensionAssociationCollection.new(dimension_definitions)
      end

      def metric_definitions
        @metric_definitions ||= Schema::MetricDefinitionCollection.new(@cube)
      end
      alias_method :metrics, :metric_definitions

      def main_query(&scope)
        @scope = scope
      end

      def name
        'main'
      end

      # @return [Runtime::MainFactScope]
      def build
        Runtime::MainFactScope.new(self)
      end
    end
  end
end
