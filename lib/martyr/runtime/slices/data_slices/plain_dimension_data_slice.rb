module Martyr
  module Runtime
    class PlainDimensionDataSlice
      include Martyr::LevelComparator

      # @attribute level [BaseLevelDefinition]
      attr_reader :level, :slice_definition

      attr_reader :dimension_definition
      delegate :id, :name, to: :level, prefix: true

      def initialize(dimension_definition)
        @dimension_definition = dimension_definition
      end

      def inspect_part
        to_hash.inspect
      end

      def to_hash
        {level_id => slice_definition.to_hash}
      end

      def dimension_name
        dimension_definition.name
      end

      # Sets the slice if this is the first time the dimension slice was referenced or if the level is equal to or lower
      # than the existing slice's level
      # @param level [BaseLevelDefinition]
      def set_slice(level, **options)
        @level = more_detailed_level(level, @level)
        return unless @level == level
        @slice_definition = PlainDimensionLevelSliceDefinition.new(options)
      end

      def add_to_grain(grain)
        grain.add_granularity(level.id)
      end

      # Add to where has two distinct strategies:
      # FACT
      #   if the level is directly connected to the fact, it will perform the query directly on the fact.
      # JOIN
      #   otherwise, the common denominator will be saught

      # set_slice
      #   - if query - run the SQL and build cache
      #   - if degenerate - run the special set_slice_from_degenerate on the closest query
      # get_slice
      #   - if cache exists, use it
      #   - if cache does not exist:
      #     - if query - look at the slice above me to calculate my slice
      #     - if degenerate - look at the query and asks for get_slice

      # @param fact_scopes [Runtime::FactScopeCollection]
      # @param dimension_bus [Runtime::QueryContext]
      def add_to_where(fact_scopes, dimension_bus)
        scope_operator = FactScopeOperatorForDimension.new(dimension_name, level_name) do |operator|
          common_denominator_level = operator.common_denominator_level(level)

          if common_denominator_level.name == level_name and level.degenerate?
            add_to_where_using_fact_strategy(operator)
          else
            add_to_where_using_join_strategy(operator, common_denominator_level, dimension_bus)
          end
        end
        fact_scopes.add_scope_operator(scope_operator)
      end

      def add_to_where_using_fact_strategy(operator)
        level_key = operator.level_key_for_where(level.id)
        operator.decorate_scope do |scope|
          if slice_definition.null?
            scope.where('0=1')
          elsif slice_definition.with.present?
            scope.where(level_key => slice_definition.with)
          elsif slice_definition.without.present?
            scope.where.not(level_key => slice_definition.without)
          end
        end
      end

      def add_to_where_using_join_strategy(operator, common_denominator_level, dimension_bus)
        dimension_bus.with_level_scope(level.id) do |level_scope|
          if slice_definition.null?
            level_scope.nullify
          elsif slice_definition.with.present?
            level_scope.slice_with(slice_definition.with)
          elsif slice_definition.without.present?
            level_scope.slice_without(slice_definition.without)
          end unless level_scope.loaded?
        end

        dimension_bus.with_level_scope(common_denominator_level.id) do |common_level|
          operator.decorate_scope do |scope|
            level_key = operator.level_key_for_where(common_level.id)
            scope.where(level_key => common_level.keys)
          end
        end
      end

    end
  end
end
