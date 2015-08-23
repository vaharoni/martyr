module Martyr
  module Runtime
    class DimensionScopeOperator < BaseScopeOperator
      include Martyr::LevelComparator

      attr_reader :dimension_name, :level_name, :block
      delegate :level_key_for_where, to: :fact_scope

      def initialize(dimension_name, level_name, &block)
        @dimension_name = dimension_name
        @level_name = level_name
        @block = block
      end

      def supported?
        fact_scope.supports_dimension_level?(dimension_name, level_name)
      end

      def common_denominator_level(level)
        common_level = find_common_denominator_level(level, fact_scope.dimensions[dimension_name].level_objects)

        # This should never be raised, since the QueryGrain should have already nullified the cube
        raise Internal::Error.new("Internal error: Dimension `#{dimension_name}` slice on level `#{level_name}` has no common denominator.") unless common_level
        common_level
      end

    end
  end
end