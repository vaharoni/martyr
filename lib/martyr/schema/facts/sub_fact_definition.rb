module Martyr
  module Schema
    class SubFactDefinition < BaseFactDefinition
      attr_reader :name, :join_clause, :join_on

      delegate :main_fact, :dimension_definitions, to: :cube

      delegate :find_level_association, to: :dimension_associations

      def initialize(cube, name, &block)
        @cube = cube
        @name = name.to_s
        @dimension_associations = DimensionAssociationCollection.new(dimension_definitions)
        @joins_by_default = false

        scope = instance_eval(&block)
        @scope = -> { scope }
      end

      def supports_metric?(*)
        false
      end

      def has_dimension_level(dimension_name, level_name, **args)
        raise Schema::Error.new("Dimension level `#{dimension_name}.#{level_name}` does not exist in main query") unless
            main_fact.has_dimension_level?(dimension_name, level_name)

        dimension_associations.has_dimension_level(dimension_name, level_name, **args)
      end

      def joins_with(join_clause, on:, by_default: false)
        @join_clause = join_clause
        @join_on = on
        @joins_by_default = by_default
      end

      # @return [Runtime::SubFactScope]
      def build
        Runtime::SubFactScope.new(self)
      end

    end
  end
end
