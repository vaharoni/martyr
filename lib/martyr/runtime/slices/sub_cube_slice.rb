module Martyr
  module Runtime
    class SubCubeSlice

      attr_accessor :sub_cube, :slices

      include Martyr::Delegators
      each_child_delegator :add_to_grain, :add_to_where, to: :slice_objects

      def initialize(sub_cube)
        @sub_cube = sub_cube
        @slices = {}
      end

      def inspect
        "#<#{self.class} #{inspect_part}>"
      end

      def inspect_part
        "slices: {#{@slices.values.map(&:inspect_part).join(', ')}}"
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

      def metric_slices
        @_metric_slices ||= slice_objects.select{|x| x.is_a?(Runtime::MetricSlice)}
      end

    end
  end
end