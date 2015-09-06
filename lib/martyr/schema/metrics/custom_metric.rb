module Martyr
  module Schema
    class CustomMetric < BaseMetric

      attr_accessor :block

      def build_data_slice(*)
        raise Runtime::Error.new("Custom metrics cannot be sliced: attempted on metric `#{name}`")
      end

      def build_memory_slice(*args)
        Runtime::MetricMemorySlice.new(self, *args)
      end

      # @param fact_scopes [Runtime::FactScopeCollection]
      def add_to_select(fact_scopes)
        # no-op
      end

      def extract(fact)
        block.call(fact)
      end

    end
  end
end
