module Martyr
  module Runtime
    class QueryGrain
      include Martyr::LevelComparator

      attr_reader :sub_cube, :grain

      def initialize(sub_cube)
        @sub_cube = sub_cube
        @grain = {}
        @null = false
      end

      def inspect
        "#<#{self.class} #{inspect_part}>"
      end

      def inspect_part
        inspection = grain.map{|k,level| "#{k}: :#{level.name}"}.join(', ')
        "grain: {#{inspection}}"
      end

      def null?
        @null
      end

      # Maintains for every dimension the lowest supported level
      # @param dimension_name [String, Symbol]
      # @param level_name [String, Symbol]
      def add_granularity(dimension_name, level_name)
        dimension = sub_cube.find_dimension(dimension_name)
        level = dimension.find_level(level_name)
        level_to_add = find_common_denominator_level(level, dimension.levels.supported_levels)
        @null = true and return unless level_to_add

        @grain[dimension_name.to_s] = more_detailed_level(@grain[dimension.to_s], level_to_add)
      end

      def set_all_if_empty
        return if @grain.present?
        sub_cube.dimension_scopes.each do |dimension_name, dimension_object|
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
          sub_cube.find_dimension(dimension_name).level_and_above_supported(lowest_level.name).each do |level_object|
            yield level_object
          end
        end
      end

    end
  end
end
