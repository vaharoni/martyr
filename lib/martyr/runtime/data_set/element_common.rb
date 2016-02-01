module Martyr
  module Runtime

    # Requirements:
    #   The object must have the #store method

    module ElementCommon
      extend ActiveSupport::Concern

      included do
        attr_reader :metrics_hash
      end

      # Grain and coordinates are different.
      # Coordinates can include "background" multi-value slices such as: 'media.types' => ['a', 'b', 'c']
      # Grain always have one value for each level
      # Coordinates always include the grain.

      def grain_has_level_id?(level_id)
        grain_level_ids.include?(level_id)
      end

      def coordinates_have_level_id?(level_id)
        coordinates.keys.include?(level_id)
      end
      alias_method :has_level_id?, :coordinates_have_level_id?

      def metrics
        metrics_hash.values
      end

      def metric_ids
        metrics_hash.keys
      end

      # @param metrics [Array<BaseMetric>]
      # @return [self]
      def rollup(*metrics)
        @metrics_hash ||= {}
        metrics.each do |metric|
          next if @metrics_hash[metric.id]
          value = empty? ? 0 : FutureMetric.wrap(self, metric, :rollup)
          store metric.id, value
          @metrics_hash[metric.id] = metric
        end
        self
      end

    end
  end
end
