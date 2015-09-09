module Martyr
  module Runtime
    class Element < HashWithIndifferentAccess

      attr_reader :facts
      delegate :grain_hash, to: :coordinates_object

      # @param address_resolver [#element_by_memory_slice]
      # @param grain [Hash] {level_name => level_value}
      # @param facts [Array<Fact>]
      # @param memory_slice [MemorySlice]
      def initialize(address_resolver, grain, facts, memory_slice)
        @address_resolver = address_resolver
        @coordinates = Coordinates.new(grain_hash: grain, memory_slice: memory_slice, dimension_bus: address_resolver.dimension_bus)
        @facts = facts
        @metrics = []
        merge! grain
      end

      # @param metrics [Array<BaseMetric>]
      def rollup(*metrics)
        @metrics = metrics
        metrics.each do |metric|
          store metric.id, metric.rollup(self)
        end
      end

      # @option standardizer [MetricIdStandardizer] default is identity
      # @option exclude_metric_ids [String, Array<String>] default is []
      def locate(*several_variants)
        if several_variants.length == 2
          standardizer = several_variants[1].delete(:standardizer) || MetricIdStandardizer.new
          exclude_metric_ids = several_variants[1].delete(:exclude_metric_ids)
          slice_hash = { several_variants[0] => several_variants[1] }
          reset_arr = []
        elsif several_variants.length == 1 and several_variants.first.is_a?(Hash)
          slice_hash = several_variants.first
          standardizer = slice_hash.delete(:standardizer) || MetricIdStandardizer.new
          exclude_metric_ids = slice_hash.delete(:exclude_metric_ids)
          reset_arr = Array.wrap(slice_hash.delete(:reset))
        else
          raise ArgumentError.new("wrong number of arguments #{several_variants.length} for (1..2)")
        end

        new_coords = coordinates_object.locate(standardizer.standardize(slice_hash), reset: standardizer.standardize(reset_arr))
        element_by_address(new_coords, exclude_metric_ids: Array.wrap(exclude_metric_ids))
      end

      def coordinates
        @coordinates.to_hash
      end

      def coordinates_object
        @coordinates
      end

      private

      def element_by_address(coordinates, exclude_metric_ids: [])
        elm = @address_resolver.get_element(coordinates)
        throw(:empty_element) unless elm
        elm.rollup *@metrics.reject{|m| exclude_metric_ids.include? m.id}
        elm
      end

    end
  end
end
