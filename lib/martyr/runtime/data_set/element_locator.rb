module Martyr
  module Runtime

    # This is a service object that allows locating an element given element coordinates and "locate instructions".
    # It is structured to allow locating elements even in the absence of a real element to "start from".

    class ElementLocator
      include ActiveModel::Model

      # @attribute cube_name [String]

      # @attribute memory_slice [MemorySlice] the current slice needs to be injected to coordinates. @see Coordinates.

      # @attribute address_resolver [#dimension_bud, #get_element] currently a FactIndexer.

      # @attribute metrics [Array<BaseMetric>] the metrics that should be rolled up on the located element

      # @attribute restrict_levels [Array<String>] optional array of supported level IDs. If provided, any request to
      #   locate a level outside this list will result in nil value.

      # @attribute standardizer [MetricIdStandardizer] this is optional. If provide, it will be used to "standardize"
      #   the new location hash and the reset array, which means adding the cube name to metrics without a cube name.

      attr_accessor :cube_name, :memory_slice, :address_resolver, :metrics, :restrict_levels, :standardizer
      delegate :dimension_bus, to: :address_resolver

      # Get an element based on existing coordinates hash
      def get(coordinates_hash)
        return nil if restrict_levels.present? and (coordinates_hash.keys - restrict_levels).present?
        with_coordinates(coordinates_hash) do |coordinates|
          get_element coordinates
        end
      end

      # Get an element based on existing coordinates hash AND changes instructions sent to #locate
      def locate(coordinates_hash, *locate_args)
        with_coordinates(coordinates_hash) do |coordinates|
          locate! coordinates, *locate_args
        end
      end

      private

      def standardizer_with_default
        @standardizer || MetricIdStandardizer.new
      end

      def with_coordinates(coordinates_hash)
        memory_slice.for_cube_name(cube_name) do |scoped_memory_slice|
          coordinates = Coordinates.new grain_hash: coordinates_hash,
            memory_slice: scoped_memory_slice,
            dimension_bus: dimension_bus

          yield coordinates
        end
      end

      def get_element(coordinates)
        elm = address_resolver.get_element(coordinates)
        return nil unless elm
        elm.rollup *metrics
        elm
      end

      def locate!(coordinates, *several_variants)
        if several_variants.length == 2
          slice_hash = { several_variants[0] => several_variants[1] }
          reset_arr = []
        elsif several_variants.length == 1 and several_variants.first.is_a?(Hash)
          slice_hash = several_variants.first.dup
          reset_arr = Array.wrap(slice_hash.delete(:reset))
        else
          raise ArgumentError.new("wrong number of arguments #{several_variants.length} for (1..2)")
        end

        new_coords = coordinates.locate(standardizer_with_default.standardize(slice_hash),
          reset: standardizer_with_default.standardize(reset_arr))

        return nil if restrict_levels.present? and (new_coords.grain_hash.keys - restrict_levels).present?
        get_element(new_coords)
      end

    end
  end
end
