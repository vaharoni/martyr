# This class is used in two cases:
# For facts:
#   To prevent calculation of custom metrics as user code may rely on dimension initialization during
#   the process of figuring out which keys should be initialized.
#
# For elements:
#   To prevent infinite recursion that can be caused if a cube has two custom rollups that call `locate`.
#   The result would be that the calculations oscillates between the two metrics on the newly located element.

module Martyr
  module Runtime
    class FutureMetric

      # @param element_or_fact [Element, Fact]
      # @param metric [BaseMetric]
      # @param method [:rollup, :extract]
      def self.wrap(element_or_fact, metric, method)
        if metric.is_a?(Martyr::Schema::BuiltInMetric)
          metric.send(method, element_or_fact)
        else
          proc = -> { metric.send(method, element_or_fact) }
          new(proc)
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
