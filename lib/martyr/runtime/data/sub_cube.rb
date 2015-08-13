module Martyr
  module Runtime
    class SubCube

      attr_reader :query_context, :fact_scopes
      delegate :compound_slice, to: :query_context

      def initialize(query_context)
        @query_context = query_context
        @fact_scopes = query_context.send(:build_fact_scope_context)
      end

      def execute
        compound_slice.apply_on_data(fact_scopes)
      end

    end
  end
end
