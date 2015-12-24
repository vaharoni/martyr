module Martyr
  module Runtime
    class WhereOperatorForDimension < BaseOperator
      include Martyr::LevelComparator

      attr_reader :dimension_name, :level_name, :block
      delegate :level_key_for_where, to: :fact_scope

      alias_method :add_where, :operate

      def initialize(dimension_name, level_name, &block)
        super(&block)
        @dimension_name = dimension_name
        @level_name = level_name
      end

      # = Support methods (@fact_scope is initialized)

      def common_denominator_level(level_definition)
        common_level = find_common_denominator_level(level_definition, fact_scope.dimensions[dimension_name].level_objects)

        # This should never be raised, since the QueryGrain should have already nullified the cube
        raise Internal::Error.new("Internal error: Dimension `#{dimension_name}` slice on level `#{level_name}` has no common denominator.") unless common_level
        common_level
      end

      private

      def handle_inner(fact_scope)
        fact_scope.decorate_scope {|scope| scope.where(*operation_args) }
      end

      def run_for_sub_fact?
        true
      end

      def supported_for?(fact_scope)
        fact_scope.supports_dimension_level?(dimension_name, level_name)
      end

    end
  end
end
