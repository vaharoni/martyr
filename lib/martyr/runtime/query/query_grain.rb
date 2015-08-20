module Martyr
  module Runtime
    class QueryGrain
      include Martyr::LevelComparator

      attr_reader :cube, :grain

      def initialize(cube)
        @cube = cube
        @grain = {}
        @null = false
      end

      def null?
        @null
      end

      # @param dimension [String, Symbol]
      # @param level [String, Symbol]
      def add_granularity(dimension, level)
        level_definition = cube.find_dimension_definition(dimension).find_level(level)
        level_association_collection = cube.find_dimension(dimension).levels
        level_to_add = find_common_denominator_level(level_definition, level_association_collection)
        @null = true and return unless level_to_add

        @grain[dimension.to_s] = more_detailed_level(@grain[dimension.to_s], level_to_add)
      end

      def set_all_if_empty
        return if @grain.present?
        cube.dimensions.each do |dimension_name, dimension_object|
          @grain[dimension_name.to_s] = dimension_object.lowest_level
        end
      end

      def nullify_scope_if_null(fact_scopes)
        fact_scopes.set_null_scope if null?
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
        each_supported_level do |level_object|
          fact_scopes.main_fact.decorate_scope do |scope|
            scope.group(level_object.fact_key)
          end
        end
      end

      private

      def each_supported_level
        return if null?
        grain.each do |dimension_name, lowest_level|
          cube.find_dimension(dimension_name).level_and_above_supported(lowest_level.name).each do |_level_name, level_object|
            yield level_object
          end
        end
      end

    end
  end
end
