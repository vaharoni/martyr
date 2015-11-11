module Martyr
  module Runtime
    class MetricDataSlice
      attr_reader :metric, :slice_definition
      delegate :to_hash, to: :slice_definition
      delegate :cube_name, to: :metric
      delegate :id, to: :metric, prefix: true

      def initialize(metric)
        @metric = metric
      end

      def keys
        [metric_id]
      end

      def set_slice(_metric_definition, **options)
        raise Martyr::Error.new('Internal error. Inconsistent metric received') unless _metric_definition.id == metric_id
        @slice_definition = MetricSliceDefinition.new(metric: metric, **options)
      end

      def get_slice(_metric_id)
        raise Martyr::Error.new('Internal error. Inconsistent metric received') unless _metric_id == metric_id
        @slice_definition
      end

      def add_to_dimension_scope(*)
        # no-op
      end

      def add_to_grain(*)
        # no-op
      end

      # @param fact_scopes [Runtime::FactScopeCollection]
      def add_to_where(fact_scopes, *)
        scope_operator = FactScopeOperatorForMetric.new(metric_id) do |operator|
          operator.decorate_scope do |scope|
            slice_definition.combined_statements.inject(scope) do |scope, or_statements|
              scope.having(compile_or_statement_group(or_statements), *or_statements.map{|slice_statement| slice_statement[:value]})
            end
          end
        end
        fact_scopes.add_scope_operator(scope_operator)
      end

      private

      def compile_or_statement_group(or_statement_group)
        or_statement_group.map do |slice_statement|
          "#{metric.statement} #{slice_statement[:data_operator]} ?"
        end.join(' OR ')
      end
    end
  end
end
