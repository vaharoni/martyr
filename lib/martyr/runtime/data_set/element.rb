module Martyr
  module Runtime
    class Element < HashWithIndifferentAccess

      # @attribute element_locator [ElementLocator] this is added to an element in the process of building it
      attr_accessor :element_locator

      attr_reader :facts, :metrics

      # @param coordinates [Coordinates]
      # @param facts [Array<Fact>]
      def initialize(coordinates, facts)
        @coordinates = coordinates
        @facts = facts
        @metrics = []
        merge! coordinates.grain_hash
      end

      # @param metrics [Array<BaseMetric>]
      def rollup(*metrics)
        @metrics = metrics
        metrics.each do |metric|
          store metric.id, metric.rollup(self)
        end
      end

      def coordinates
        @coordinates.to_hash
      end

      def coordinates_object
        @coordinates
      end

      def locate(*args)
        @element_locator.locate(coordinates, *args)
      end

    end
  end
end
