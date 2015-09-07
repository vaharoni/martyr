module Martyr
  module Runtime
    class PlainDimensionDataSlice
      # @attribute levels [Hash<String => PlainDimensionLevelSliceDefinition>]
      attr_reader :levels, :slice_definition

      attr_reader :dimension_definition
      delegate :id, :name, to: :levels, prefix: true

      def initialize(dimension_definition)
        @dimension_definition = dimension_definition
        @levels = {}
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
        @levels[level.id] = PlainDimensionLevelSliceDefinition.new(options)
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
          apply_slice_on_level dimension_bus.level_scope(level_id)

          common_denominator_level = operator.common_denominator_level(level)
          if common_denominator_level.name == level_name and level.degenerate?
            add_to_where_using_fact_strategy(operator)
          else
            add_to_where_using_join_strategy(operator, dimension_bus.level_scope(common_denominator_level.id))
          end
        end
        fact_scopes.add_scope_operator(scope_operator)
      end

      def apply_slice_on_level(level_scope)
        if slice_definition.null?
          level_scope.nullify
        elsif slice_definition.with.present?
          level_scope.slice_with(slice_definition.with)
        elsif slice_definition.without.present?
          level_scope.slice_without(slice_definition.without)
        end
      end

      def add_to_where_using_fact_strategy(operator)
        level_key = operator.level_key_for_where(level.id)

        operator.decorate_scope do |fact_scope|
          if slice_definition.null?
            fact_scope.where('0=1')
          elsif slice_definition.with.present?
            fact_scope.where(level_key => slice_definition.with)
          elsif slice_definition.without.present?
            fact_scope.where.not(level_key => slice_definition.without)
          end
        end
      end

      def add_to_where_using_join_strategy(operator, common_level_scope)
        operator.decorate_scope do |scope|
          level_key = operator.level_key_for_where(common_level_scope.id)
          scope.where(level_key => common_level_scope.keys)
        end
      end
    end
  end
end
