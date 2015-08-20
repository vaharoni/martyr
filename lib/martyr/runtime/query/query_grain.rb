module Martyr
  module Runtime
    class QueryGrain
      include Martyr::LevelComparator

      attr_reader :cube, :grain

      def initialize(cube)
        @cube = cube
        @grain = {}
      end

      # @param dimension [String, Symbol]
      # @param level [String, Symbol]
      def add_granularity(dimension, level)
        level = cube.find_dimension(dimension).find_level(level)
        @grain[dimension.to_s] = more_detailed_level(@grain[dimension.to_s], level)
      end

      def set_all_if_empty
        return if @grain.present?
        cube.dimensions.each do |dimension_name, dimension_object|
          @grain[dimension_name.to_s] = dimension_object.lowest_level
        end
      end

      # Adds all supported levels including and above the sliced level
      # @param fact_scopes [Runtime::FactScopeCollection]
      def add_to_select(fact_scopes)
        each_supported_level do |level_object|
          fact_scopes.main_fact.decorate_scope do |scope|
            scope.select("#{level_object.fact_key} AS #{level_object.fact_alias}")
          end
        end
      end

      # @param fact_scopes [Runtime::FactScopeCollection]
      def add_to_group_by(fact_scopes)
        each_supported_level do |level_object, dimension_name|
          fact_scopes.main_fact.decorate_if_supports(dimension_name: dimension_name, level_name: level_object.name) do |scope|
            scope.group(level_object.fact_key)
          end
        end
      end

      private

      def each_supported_level
        grain.each do |dimension_name, lowest_level|
          cube.find_dimension(dimension_name).level_and_above(lowest_level.name).each do |_level_name, level_object|
            yield level_object, dimension_name
          end
        end
      end

    end
  end
end
