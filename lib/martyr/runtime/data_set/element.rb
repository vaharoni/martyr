module Martyr
  module Runtime
    class Element < HashWithIndifferentAccess

      attr_reader :facts, :metrics
      delegate :grain_hash, to: :coordinates_object
      delegate :cube_name, to: :@address_resolver

      # @param address_resolver [#dimension_bus, #get_element, #cube_name]
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

      def coordinates
        @coordinates.to_hash
      end

      def coordinates_object
        @coordinates
      end

      # Examples:
      #   locate('customers.city', with: 'Dover')
      #   locate('customers.city' => {with: 'Dover'}, 'customers.country' => {with: 'USA'}, 'cube.amount' => {gt: 10}, reset: ['genres.name', 'media_types.*'])
      #
      # @option standardizer [MetricIdStandardizer] default is identity
      # @option exclude_metric_ids [String, Array<String>] default is []. This is useful when calculating a #locate
      #   request during the resolution of a calculated metric - we don't want this metric to recalculate itself for
      #   the found element (recursion is not allowed)
      #
      def locate(*several_variants)
        if several_variants.length == 2
          hash = {several_variants[0] => several_variants[1].except(:standardizer, :exclude_metric_ids)}
          options = several_variants[1].slice(:standardizer, :exclude_metric_ids)
        elsif several_variants.length == 1 and several_variants.first.is_a?(Hash)
          hash = several_variants[0].except(:standardizer, :exclude_metric_ids)
          options = several_variants[0].slice(:standardizer, :exclude_metric_ids)
        else
          raise ArgumentError.new("wrong number of arguments #{several_variants.length} for (1..2)")
        end
        element_locator(**options).locate(hash) || throw(:empty_element)
      end

      private

      # @return [ElementLocator]
      def element_locator(standardizer: nil, exclude_metric_ids: [])
        metrics_to_rollup = metrics.reject{|m| exclude_metric_ids.include? m.id}

        ElementLocator.new(cube_name: cube_name, memory_slice: memory_slice, address_resolver: @address_resolver,
          metrics: metrics_to_rollup, standardizer: standardizer)
      end


      # TODO: REMOVE
      #
      # Examples:
      #   locate('customers.city', with: 'Dover')
      #   locate('customers.city' => {with: 'Dover'}, 'customers.country' => {with: 'USA'}, 'cube.amount' => {gt: 10}, reset: ['genres.name', 'media_types.*'])
      #
      # @option standardizer [MetricIdStandardizer] default is identity
      # @option exclude_metric_ids [String, Array<String>] default is []
      # def _locate(*several_variants)
      #   if several_variants.length == 2
      #     standardizer = several_variants[1].delete(:standardizer) || MetricIdStandardizer.new
      #     exclude_metric_ids = several_variants[1].delete(:exclude_metric_ids)
      #     slice_hash = { several_variants[0] => several_variants[1] }
      #     reset_arr = []
      #   elsif several_variants.length == 1 and several_variants.first.is_a?(Hash)
      #     slice_hash = several_variants.first.dup
      #     standardizer = slice_hash.delete(:standardizer) || MetricIdStandardizer.new
      #     exclude_metric_ids = slice_hash.delete(:exclude_metric_ids)
      #     reset_arr = Array.wrap(slice_hash.delete(:reset))
      #   else
      #     raise ArgumentError.new("wrong number of arguments #{several_variants.length} for (1..2)")
      #   end
      #
      #   new_coords = coordinates_object.locate(standardizer.standardize(slice_hash), reset: standardizer.standardize(reset_arr))
      #   element_by_address(new_coords, exclude_metric_ids: Array.wrap(exclude_metric_ids))
      # end
      #
      # private
      #
      # def element_by_address(coordinates, exclude_metric_ids: [])
      #   elm = @address_resolver.get_element(coordinates)
      #   throw(:empty_element) unless elm
      #   elm.rollup *@metrics.reject{|m| exclude_metric_ids.include? m.id}
      #   elm
      # end

    end
  end
end
