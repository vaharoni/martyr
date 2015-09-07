module Martyr
  module Runtime
    class MemorySlice

      attr_reader :sub_cube_slice, :dimension_bus
      delegate :definition_object_for, to: :sub_cube_slice

      def initialize(sub_cube_slice, dimension_bus)
        @sub_cube_slice = sub_cube_slice
        @memory_slice_overrides = {}
        @dimension_bus = dimension_bus
      end

      # @param slice_on [String] e.g. 'customers.last_name' or 'amount_sold'
      # @param slice_definition [Hash]
      def slice(slice_on, slice_definition)
        slice_on_object = definition_object_for(slice_on)
        slice_id = slice_on_object.slice_id
        @memory_slice_overrides[slice_id] ||= slice_on_object.build_memory_slice(dimension_bus, sub_cube_slice.slices[slice_id])
        @memory_slice_overrides[slice_id].set_slice(slice_on_object, **slice_definition.symbolize_keys)
      end
    end
  end
end
