module Martyr
  module Runtime
    class PlainDimensionDataSlice
      include Martyr::Runtime::HasScopedLevels

      # @attribute levels [Hash<String => PlainDimensionLevelSliceDefinition>]
      attr_reader :levels

      attr_reader :dimension_definition
      delegate :keys, to: :sorted_levels

      def initialize(dimension_definition)
        @dimension_definition = dimension_definition
        @levels = {}
      end

      def sorted_levels
        arr = scoped_levels.sort_by{|_level_id, slice| slice.level.to_i}
        Hash[arr]
      end

      def to_hash
        sorted_levels.values.inject({}) {|h, slice| h.merge! slice.to_hash}
      end

      def dimension_name
        dimension_definition.name
      end

      # @param level [BaseLevelDefinition]
      def set_slice(level, **options)
        @levels[level.id] = PlainDimensionLevelSliceDefinition.new(level: level, **options)
      end

      # @return [PlainDimensionLevelSliceDefinition]
      def get_slice(level_id)
        scoped_levels[level_id]
      end

      # = Slicing the dimension

      def add_to_dimension_scope(dimension_bus)
        scoped_levels.keys.each do |level_id|
          level_scope = dimension_bus.level_scope(level_id)
          slice_definition = levels[level_id]

          add_slice_to_dimension_level(level_scope, slice_definition)
        end
      end

      def add_slice_to_dimension_level(level_scope, slice_definition)
        return unless level_scope.sliceable?
        if slice_definition.null?
          level_scope.nullify
        elsif slice_definition.with.present?
          level_scope.slice_with(slice_definition.with)
        end
      end

      # = Slicing the fact

      def add_to_grain(grain)
        scoped_levels.keys.each {|level_id| grain.add_granularity(level_id) }
      end

      # @param fact_scopes [Runtime::FactScopeCollection]
      # @param dimension_bus [Runtime::QueryContext]
      def add_to_where(fact_scopes, dimension_bus)
        scoped_levels.keys.each do |level_id|
          add_one_level_to_where(fact_scopes, level_id, dimension_bus)
        end
      end

      private

      # @return [FactScopeOperatorForDimension]
      def add_one_level_to_where(fact_scopes, level_id, dimension_bus)
        level_scope = dimension_bus.level_scope(level_id)
        slice_definition = get_slice(level_id)

        # Building operator used to slice the fact
        fact_scopes.add_where_operator_for_dimension(level_scope.dimension_name, level_scope.name) do |operator|
          if slice_definition.null?
            operator.decorate_scope {|fact_scope| fact_scope.where('0=1')}
            next
          end

          common_denominator_level = operator.common_denominator_level(level_scope.level_definition)
          if common_denominator_level.name == level_scope.name
            add_to_where_using_fact_strategy(level_scope, slice_definition, operator)
          else
            add_to_where_using_join_strategy(operator, dimension_bus.level_scope(common_denominator_level.id))
          end
        end
      end

      def add_to_where_using_fact_strategy(level_scope, slice_definition, operator)
        return unless slice_definition.with.present?
        level_key = operator.level_key_for_where(level_scope.id)
        operator.add_where("(#{level_key}) IN (?)", slice_definition.with)
      end

      def add_to_where_using_join_strategy(operator, common_level_scope)
        level_key = operator.level_key_for_where(common_level_scope.id)
        operator.add_where("(#{level_key}) IN (?)", common_level_scope.keys)
      end
    end
  end
end
