module Martyr
  module Runtime
    class SubCubeGrain
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
      def add_granularity(level_id)
        level_to_add = sub_cube.common_denominator_level_association(level_id)
        @null = true and return unless level_to_add
        dimension = level_to_add.dimension_name
        @grain[dimension] = more_detailed_level(@grain[dimension], level_to_add)
      end

      def set_all_if_empty
        return if @grain.present?
        sub_cube.dimension_associations.each do |dimension_name, dimension_object|
          @grain[dimension_name.to_s] = dimension_object.lowest_level
        end
      end

      def nullify_scope_if_null(fact_scopes)
        fact_scopes.set_null_scope if null?
      end

      # Adds all supported levels including and above the sliced level
      # @param fact_scopes [Runtime::FactScopeCollection]
      def add_to_select(fact_scopes)
        supported_levels.each do |level_object|
          fact_scopes.main_fact.decorate_scope do |scope|
            scope.select("#{level_object.fact_key} AS #{level_object.fact_alias}")
          end
        end
      end

      # @param fact_scopes [Runtime::FactScopeCollection]
      def add_to_group_by(fact_scopes)
        supported_levels.each do |level_object|
          fact_scopes.main_fact.decorate_scope do |scope|
            scope.group(level_object.fact_key)
          end
        end
      end

      private

      def supported_levels
        return [] if null?
        grain.flat_map do |_dimension_name, lowest_level|
          sub_cube.association_from_id(lowest_level.id).level_and_above
        end
      end

    end
  end
end
