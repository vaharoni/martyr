module Martyr
  module Runtime
    class SubCubeSlice

      attr_accessor :sub_cube, :slices

      include Martyr::Delegators
      each_child_delegator :add_to_grain, :add_to_where, to: :slice_objects

      include Martyr::Translations

      # TODO: sub_cube here is really just needed to resolve definition objects. Change to QueryContext instead of sub cube.
      def initialize(sub_cube)
        @sub_cube = sub_cube
        @slices = {}
      end

      def inspect
        "#<#{self.class} #{inspect_part}>"
      end

      def inspect_part
        to_hash.inspect
      end

      def to_hash
        slice_objects.inject({}) {|h,slice| h.merge! slice.to_hash}
      end

      def definition_object_for(slice_on)
        sub_cube.definition_from_id(slice_on) || raise(Query::Error.new("Could not find `#{slice_on}` to apply slice on"))
      end

      # @param slice_on [String] e.g. 'customers.last_name' or 'amount_sold'
      # @param slice_definition [Hash]
      def slice(slice_on, slice_definition)
        slice_on_object = definition_object_for(slice_on)
        @slices[slice_on_object.slice_id] ||= slice_on_object.build_data_slice
        @slices[slice_on_object.slice_id].set_slice(slice_on_object, **slice_definition.symbolize_keys)
      end

      def slice_objects
        slices.values
      end

      # @return [PlainDimensionDataSlice]
      def dimension_slice_for_level(level_id)
        dimension = slices[first_element_from_id(level_id)]
        raise Internal::Error.new("Cannot find level #{level_id} in sub cube slice grain") unless dimension
        dimension
      end

      # @param level [Martyr::Level]
      # @return [nil, Integer]
      #   nil     the dimension does not exist in the grain
      #   0       the dimension exists in the slice and the level in the slice is the same as `level`
      #   1       the dimension exists in the slice and the level in the slice is lower (more detailed, higher index) than `level`
      #   -1      the dimension exists in the slice and the level in the slice is higher (less detailed, lower index) than `level`
      def compare_level_with_grain(level)
        return nil unless @slices[level.dimension_name].present?
        @slices[level.dimension_name].level.to_i <=> level.to_i
      end

    end
  end
end
