module Martyr
  module Runtime
    class Element < HashWithIndifferentAccess

      attr_reader :facts, :grain, :metric_slices

      # @param grain [Hash] {level_name => level_value}
      def initialize(grain, facts, metric_slices)
        @facts = facts
        @grain = grain
        @metric_slices = metric_slices.map(&:to_hash)
        merge! grain
      end

      # @param metrics [Array<BaseMetric>]
      def rollup(*metrics)
        metrics.each do |metric|
          store metric.id, metric.rollup(facts)
        end
      end

      def coordinates
        grain_coordinates.merge! metric_coordinates
      end

      private

      def grain_coordinates
        grain.map do |level_id, value|
          {level_id => {'with' => value}}
        end.inject({}) do |h, coords|
          h.merge! coords
        end
      end

      def metric_coordinates
        metric_slices.inject({}) do |h, coords|
          h.merge! coords
        end
      end

    end
  end
end