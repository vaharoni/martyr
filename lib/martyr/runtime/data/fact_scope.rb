module Martyr
  module Runtime
    class FactScope
      attr_reader :fact_definition, :scope
      delegate :name, to: :fact_definition

      delegate :supports_dimension?, :supports_metric?, to: :fact_definition

      # @param fact_definition [Schema::MainFactDefinition]
      def initialize(fact_definition)
        @fact_definition = fact_definition
        @scope = fact_definition.scope
      end

      # Chaining to allow lazy setup
      # @yieldparam [FactScope]
      def update_scope(dimension_name: nil, metric_name: nil, &block)
        return if dimension_name and !supports_dimension?(dimension_name)
        return if metric_name and !supports_metric?(metric_name)
        @scope = Proc.new do
          block.call(self)
        end
      end

      def scope_sql
        run_scope.try(:arel).try(:to_sql)
      end

      def run_scope
        scope.call
      end

    end
  end
end