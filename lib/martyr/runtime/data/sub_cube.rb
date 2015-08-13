module Martyr
  module Runtime
    class SubCube

      attr_reader :query_context, :fact_scopes
      delegate :sql, to: :fact_scopes

      def initialize(query_context)
        @query_context = query_context
        @fact_scopes = query_context.send(:build_fact_scope_context)
      end

      def execute
        apply_dimensions
        apply_metrics
        apply_compound_slice
        self
      end

      private

      def apply_compound_slice
        query_context.compound_slice.apply_on_data(fact_scopes)
      end

      def apply_metrics
        query_context.metrics.each do |metric|
          metric.apply_on_data(fact_scopes)
        end
      end

      def apply_dimensions
        query_context.dimensions.each do |dimension|
          dimension.apply_on_data(fact_scopes)
        end
      end

    end
  end
end
