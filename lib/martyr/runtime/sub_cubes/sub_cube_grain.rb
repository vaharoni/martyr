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
        "#<#{self.class} #{to_a}>"
      end

      def to_a
        supported_level_associations.map(&:id)
      end

      def level_ids
        grain.values.map(&:id)
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

      # TODO: delete
      # def nullify_scope_if_null(fact_scopes)
      #   fact_scopes.set_null_scope if null?
      # end

      # Adds all supported levels including and above the sliced level
      # @param fact_scopes [Runtime::FactScopeCollection]
      def add_to_select(fact_scopes)
        supported_level_associations.each do |level_object|
          fact_scopes.main_fact.decorate_scope do |scope|
            scope.select("#{level_object.fact_key} AS #{level_object.fact_alias}")
          end
        end
      end

      # @param fact_scopes [Runtime::FactScopeCollection]
      def add_to_group_by(fact_scopes)
        supported_level_associations.each do |level_object|
          fact_scopes.main_fact.decorate_scope do |scope|
            scope.group(level_object.fact_key)
          end
        end
      end

      # Assume the following levels, where (*) denotes has association to the fact
      #   L1
      #     L2 (*)
      #       L3 (*)
      #         L4 (*)
      #
      # Assuming the lowest level in the grain is L3:
      #
      #   supported_level_associations
      #   # => [L2, L3] of LevelAssociation objects
      #
      #   supported_level_definitions
      #   # => [L1, L2, L3] of BaseLevelDefinition objects
      #
      #   [L1, L2, L3, L4].map{|x| x.has_association_with_level(x) }
      #   # => [false, true, true, false]
      #

      def supported_level_associations
        return [] if null?
        @supported_level_associations ||= grain.flat_map do |_dimension_name, lowest_level|
          sub_cube.association_from_id(lowest_level.id).level_and_above
        end
      end

      def supported_level_definitions
        return [] if null?
        @_supported_level_definitions ||= grain.flat_map do |_dimension_name, lowest_level|
          sub_cube.definition_from_id(lowest_level.id).level_and_above
        end
      end

      def supported_level_associations_lookup
        @_supported_level_associations_lookup ||= supported_level_associations.index_by(&:id)
      end

      def has_association_with_level?(level_id)
        !!supported_level_associations_lookup[level_id]
      end
    end
  end
end
