module Martyr
  module Runtime
    class Element < HashWithIndifferentAccess

      # @attribute element_locator [ElementLocator] this is added to an element in the process of building it
      attr_accessor :element_locator

      attr_reader :facts
      delegate :cube_name, to: :element_locator
      delegate :grain_level_ids, :grain_hash, to: :@coordinates

      # @param coordinates [Coordinates]
      # @param facts [Array<Fact>]
      def initialize(coordinates, facts)
        @coordinates = coordinates
        @facts = facts
        @metrics_hash = {}

        merge! coordinates.grain_hash
      end

      # @param key [String] either metric id or level id
      def fetch(key)
        value = super(key)
        value.is_a?(FutureElementMetric) ? value.value : value
      end
      alias_method :[], :fetch

      # @param metrics [Array<BaseMetric>]
      def rollup(*metrics)
        metrics.each do |metric|
          next if @metrics_hash[metric.id]
          store metric.id, FutureElementMetric.wrap(self, metric)
          @metrics_hash[metric.id] = metric
        end
      end

      def metrics
        @metrics_hash.values
      end

      def coordinates(*)
        @coordinates.to_hash
      end

      def coordinates_object(*)
        @coordinates
      end

      def locate(*args)
        element_locator.locate(grain_hash, *args)
      end

    end
  end
end
