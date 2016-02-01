module Martyr
  module Schema
    class CustomRollup < BaseMetric
      attr_accessor :cube_name, :name, :block, :depends_on

      def build_data_slice(*)
        raise Runtime::Error.new("Rollups cannot be sliced: attempted on rollup `#{name}`")
      end

      def build_memory_slice(*)
        raise Runtime::Error.new("Rollups cannot be sliced: attempted on rollup `#{name}`")
      end

      # @param fact_scopes [Runtime::FactScopeCollection]
      def add_to_select(fact_scopes)
        # no-op
      end

      def extract(fact)
        raise Runtime::Error.new("Rollups cannot be extracted: attempted on rollup `#{name}`")
      end

      # @override
      # @param element [Runtime::Element]
      def rollup(element)
        block.call(element)
      end

    end
  end
end
