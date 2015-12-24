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

      def set_slice(metric_definition, **options)
        raise Martyr::Error.new('Internal error. Inconsistent metric received') unless metric_definition.id == metric_id
        @slice_definition = MetricSliceDefinition.new(metric: metric, **options)
      end

      def get_slice(metric_id_for_get)
        raise Martyr::Error.new('Internal error. Inconsistent metric received') unless metric_id_for_get == metric_id
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
        slice_definition.combined_statements.each do |or_statements|
          fact_scopes.add_where_operator_for_metric(metric_id) do |operator|
            operator.add_where compile_or_statement_group(or_statements),
                           *or_statements.map{|slice_statement| slice_statement[:value]}
          end
        end
      end

      private

      def compile_or_statement_group(or_statement_group)
        or_statement_group.map do |slice_statement|
          "#{metric.fact_alias} #{slice_statement[:data_operator]} ?"
        end.join(' OR ')
      end
    end
  end
end
