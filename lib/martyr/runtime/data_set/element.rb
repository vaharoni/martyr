module Martyr
  module Runtime
    class Element < HashWithIndifferentAccess

      attr_reader :facts, :grain

      # @param grain [Hash] {level_name => level_value}
      def initialize(grain, facts)
        @facts = facts
        @grain = grain
        merge! grain
      end

      # @param metrics [Array<BaseMetric>]
      def rollup(*metrics)
        metrics.each do |metric|
          store metric.id, metric.rollup(facts)
        end
      end

    end
  end
end