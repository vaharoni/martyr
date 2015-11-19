module Martyr
  module Runtime

    # Requirements:
    #   The object must have the #store method

    module ElementCommon
      extend ActiveSupport::Concern

      included do
        attr_reader :metrics_hash
      end

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
          store metric.id, FutureMetric.wrap(self, metric, :rollup)
          @metrics_hash[metric.id] = metric
        end
        self
      end

    end
  end
end
