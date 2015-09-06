module Martyr
  module Runtime
    class MetricDataSlice
      attr_reader :metric, :slice_definition

      delegate :id, to: :metric, prefix: true

      def initialize(metric)
        @metric = metric
      end

      def inspect_part
        to_hash.inspect
      end
      
      def to_hash
        { metric_id => slice_definition.to_hash }
      end

      # This allows a `between` operation with two consecutive `slice`:
      #   cube.slice(:units_sold, '>1000').slice(:units_sold, '<5000')
      def set_slice(_metric_definition, **options)
        @slice_definition = MetricSliceDefinition.new(options)
      end

      def add_to_grain(grain)
        # no-op
      end

      # @param fact_scopes [Runtime::FactScopeCollection]
      def add_to_where(fact_scopes, _dimension_bus)
        scope_operator = FactScopeOperatorForMetric.new(metric_id) do |operator|
          operator.decorate_scope do |scope|
            slice_definition.combined_statements.inject(scope) do |scope, or_statements|
              scope.having(compile_or_statement_group(or_statements))
            end
          end
        end
        fact_scopes.add_scope_operator(scope_operator)
      end

      private

      def compile_or_statement_group(or_statement_group)
        or_statement_group.map do |slice_statement|
          "#{metric.statement} #{slice_statement[:operator]} #{slice_statement[:value]}"
        end.join(' OR ')
      end
    end
  end
end
