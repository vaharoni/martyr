module Martyr
  module Runtime
    class RealElementLocator
      include ActiveModel::Model
      attr_accessor :grain_levels, :cube_name, :memory_slice, :fact_indexer, :metrics

      delegate :dimension_bus, to: :fact_indexer

      # Get an element based on existing coordinates hash
      def get(coordinates_hash)
        return nil if (coordinates_hash.keys - grain_levels).present?
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

      def with_coordinates(coordinates_hash)
        memory_slice.for_cube_name(cube_name) do |scoped_memory_slice|
          coordinates = Coordinates.new grain_hash: coordinates_hash,
            memory_slice: scoped_memory_slice,
            dimension_bus: dimension_bus

          yield coordinates
        end
      end

      def get_element(coordinates)
        elm = fact_indexer.get_element(coordinates)
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
        new_coords = coordinates.locate(slice_hash, reset: reset_arr)
        return nil if (new_coords.grain_hash.keys - grain_levels).present?
        get_element(new_coords)
      end

    end
  end
end
