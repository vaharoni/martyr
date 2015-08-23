module Martyr
  module Schema
    class SubFactDefinition < BaseFactDefinition
      attr_reader :name, :join_clause, :join_on

      delegate :main_fact, :dimension_definitions, to: :cube

      delegate :find_level, to: :dimension_associations

      def initialize(cube, name, &block)
        @cube = cube
        @name = name
        @dimension_associations = DimensionAssociationCollection.new(dimension_definitions)
        scope = instance_eval(&block)
        @scope = -> { scope }
      end

      def has_dimension_level(dimension_name, level_name, **args)
        raise Schema::Error.new("Dimension level `#{dimension_name}.#{level_name}` does not exist in main query") unless
            main_fact.has_dimension_level?(dimension_name, level_name)

        dimension_associations.has_dimension_level(dimension_name, level_name, **args)
      end

      def joins_with(join_clause, on:)
        @join_clause = join_clause
        @join_on = on
      end

      # @return [Runtime::SubFactScope]
      def build
        Runtime::SubFactScope.new(self)
      end

    end
  end
end