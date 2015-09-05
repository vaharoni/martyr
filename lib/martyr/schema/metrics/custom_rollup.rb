module Martyr
  module Schema
    class CustomRollup < BaseMetric
      include ActiveModel::Model

      attr_accessor :name, :block

      def build_slice
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
        block.call Runtime::RollupFactSet.new(element)
      end

    end
  end
end
