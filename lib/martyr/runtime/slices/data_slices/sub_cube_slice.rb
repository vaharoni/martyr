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
        "slice: #{to_hash.inspect}"
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

    end
  end
end
