module Martyr
  module Runtime
    class DataSlice

      attr_accessor :slices

      attr_reader :definition_resolver

      include Martyr::Delegators
      each_child_delegator :add_to_grain, :add_to_where, to: :slice_objects_scoped_to_cube

      include Martyr::Translations

      # = Slice definitions

      # @param definition_resolver [#definition_from_id]
      def initialize(definition_resolver)
        @definition_resolver = definition_resolver
        @slices = {}
      end

      def inspect
        to_hash.inspect
      end

      def to_hash
        slice_objects.inject({}) {|h,slice| h.merge! slice.to_hash}
      end

      # @return [Array<String>] with either metric ID or level ID (contrast with dimension name)
      def keys
        slice_objects.flat_map(&:keys)
      end

      def definition_object_for(slice_on)
        definition_resolver.definition_from_id(slice_on) || raise(Query::Error.new("Could not find `#{slice_on}` to apply slice on"))
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

      # @return [Array<String>]
      def dimension_names
        slices.reject{|_slice_id, slice_object| slice_object.is_a?(MetricDataSlice)}.keys
      end

      # = Applying slices

      def for_cube_name(cube_name)
        @cube_name_scope = cube_name
        yield self
        @cube_name_scope = nil
      end

      def slice_objects_scoped_to_cube
        return slice_objects unless @cube_name_scope
        slice_objects.select{|x| x.respond_to?(:cube_name) ? x.cube_name == @cube_name_scope : true}
      end

    end
  end
end
