module Martyr
  module Runtime
    class PlainDimensionSlice
      include Martyr::LevelComparator
      include ActiveModel::Validations


      # @attribute level [LevelDefinition]
      attr_reader :level

      attr_reader :dimension_association, :with, :without
      delegate :dimension_definition, to: :dimension_association
      delegate :name, to: :level, prefix: true

      validate do
        errors.add(:base, "Slice on `#{dimension_name}`: cannot have both `with` and `without`") if with and without
        errors.add(:base, "Slice on `#{dimension_name}`: must have either `with` and `without`") unless with or without
      end

      # @param dimension_association [Schema::DimensionAssociation]
      def initialize(dimension_association)
        @dimension_association = dimension_association
      end

      def dimension_name
        dimension_association.name
      end

      # Sets the slice if this is the first time the dimension slice was referenced or if the level is equal to or lower
      # than the existing slice's level
      def set_slice(**options)
        level = dimension_definition.find_level(options[:level])
        @level = more_detailed_level(level, @level)
        return unless @level == level
        @with = options[:with]
        @without = options[:without]
      end

      def add_to_grain(grain)
        grain.add_granularity(dimension_name, level_name)
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

      # TODO: refactor to handle join strategy
      # @param fact_scopes [Runtime::FactScopeCollection]
      def add_to_where(fact_scopes)
        level_association = find_common_denominator_level(level, dimension_association.levels)

        # This should never be raised, since the QueryGrain should have already nullified the cube
        raise Internal::Error.new("Internal error: Dimension `#{dimension_name}` slice on level `#{level_name}` has no common denominator.") unless level_association

        if level_association.name == level_name and level.degenerate?
          add_to_where_using_fact_strategy(fact_scopes)
        else
          add_to_where_using_join_strategy(fact_scopes, level_association)
        end
      end

      def add_to_where_using_fact_strategy(fact_scopes)
        fact_scopes.decorate_scopes_if_supports(dimension_name: dimension_name, level_name: level_name) do |scope, fact_scope|
          level_key = fact_scope.level_key_for_where(level)
          if with.present?
            scope.where(level_key => with)
          elsif without.present?
            scope.where.not(level_key => without)
          end
        end
      end

      # @param fact_scopes [Runtime::FactScopeCollection]
      # @param common_denominator_level [Schema::LevelAssociation]
      def add_to_where_using_join_strategy(fact_scopes, common_denominator_level)
        if with.present?
          level.slice_with(with)
        elsif without.present?
          level.slice_without(without)
        end
        fact_scopes.decorate_scopes_if_supports(dimension_name: dimension_name,
                                                level_name: common_denominator_level.name) do |scope, fact_scope|
          level_key = fact_scope.level_key_for_where(common_denominator_level)
          scope.where(level_key => common_denominator_level.level.keys)
        end
      end

    end
  end
end