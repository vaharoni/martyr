module Martyr
  module Runtime
    class Element < HashWithIndifferentAccess

      attr_reader :facts, :grain

      # @param grain [Hash] {level_name => level_value}
      # @param facts [Array<Fact>]
      # @param coordinates_resolver [CoordinatesResolver]
      def initialize(grain, facts, coordinates_resolver)
        @facts = facts
        @grain = grain
        @coordinates_resolver = coordinates_resolver
        merge! grain
      end

      # @param metrics [Array<BaseMetric>]
      def rollup(*metrics)
        metrics.each do |metric|
          store metric.id, metric.rollup(self)
        end
      end

      def coordinates
        @coordinates_resolver.resolve(self)
      end

    end
  end
end
