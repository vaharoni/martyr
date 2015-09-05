module Martyr
  module Runtime
    class SubCubeSlice

      attr_accessor :sub_cube, :slices

      include Martyr::Delegators
      each_child_delegator :add_to_grain, :add_to_where, to: :slice_objects

      include Martyr::Translations

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

      # @param slice_on [String] e.g. 'customers.last_name' or 'amount_sold'
      # @param slice_definition [Hash]
      def slice(slice_on, slice_definition)
        slice_on_object = sub_cube.definition_from_id(slice_on)
        raise Query::Error.new("Could not find `#{slice_on}` to apply slice on") unless slice_on_object

        # Treating dimension levels differently than metric slices
        if slice_on_object.respond_to?(:level_object?)
          dimension = slice_on_object.dimension_definition
          @slices[dimension.name] ||= dimension.build_slice(sub_cube.dimension_bus)
          @slices[dimension.name].set_slice(level: slice_on_object, **slice_definition.symbolize_keys)
        else
          @slices[slice_on] ||= slice_on_object.build_slice
          @slices[slice_on].set_slice(**slice_definition.symbolize_keys)
        end
      end

      def slice_objects
        slices.values
      end

      # @param hash [Hash] of the structure that is the result of applying #to_hash on the sub object,
      #   or coordinate structure: {'customers.last_name' => {with: 'White'}}
      # @return [SubCubeSlice] new object containing the result of the merging operation
      def merge_with_hash(hash)
        new_slice = self.class.new(sub_cube)
        hash.merge(to_hash).each do |slice_on, slice_definition|
          new_slice.slice(slice_on, slice_definition)
        end
      end

      # @return [PlainDimensionSlice]
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
