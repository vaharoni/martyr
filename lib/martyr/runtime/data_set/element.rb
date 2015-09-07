module Martyr
  module Runtime
    class Element < HashWithIndifferentAccess

      attr_reader :facts, :grain, :memory_slice

      # @param grain [Hash] {level_name => level_value}
      # @param facts [Array<Fact>]
      # @param memory_slice [MemorySlice]
      def initialize(grain, facts, memory_slice)
        @facts = facts
        @grain = grain
        @memory_slice = memory_slice
        merge! grain
      end

      # @param metrics [Array<BaseMetric>]
      def rollup(*metrics)
        metrics.each do |metric|
          store metric.id, metric.rollup(self)
        end
      end

      def grain_coordinates
        grain.inject({}) {|h, (level_id, level_value)| h[level_id] = {with: level_value}; h }
      end

      def coordinates
        memory_slice.to_hash.merge!(grain_coordinates)
      end

    end
  end
end
