# This class is used to prevent infinite recursion that can be caused if a cube has two custom rollups
# that call `locate`. The result would be that the calculations oscillates between the two metrics on the newly
# located element.

module Martyr
  module Runtime
    class FutureElementMetric

      # @param element [Element]
      # @param metric [BaseMetric]
      def self.wrap(element, metric)
        if metric.is_a?(Martyr::Schema::CustomRollup)
          proc = -> { metric.rollup(element) }
          new(proc)
        else
          metric.rollup(element)
        end
      end

      def initialize(proc)
        @proc = proc
      end

      def inspect
        @value.try(:inspect) || '?'
      end

      def value
        @value ||= @proc.call
      end
    end
  end
end
