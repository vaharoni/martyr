module Martyr
  module Runtime
    class MemorySlice

      attr_reader :data_slice
      delegate :definition_resolver, :definition_object_for, to: :data_slice

      def initialize(data_slice)
        @data_slice = data_slice
        @memory_slice_overrides = {}
      end

      def to_hash
        overrides = @memory_slice_overrides.values.inject({}) {|h, slice| h.merge! slice.to_hash}
        @data_slice.to_hash.merge!(overrides).slice(*keys_for_cube_scope)
      end

      def keys
        (@memory_slice_overrides.values.flat_map(&:keys) + @data_slice.keys).uniq
      end

      # @param slice_on [String]
      # @param slice_definition [Hash]
      def slice(slice_on, slice_definition)
        definition_resolver.validate_slice_on!(slice_on)
        slice_on_object = definition_object_for(slice_on)
        slice_id = slice_on_object.slice_id
        @memory_slice_overrides[slice_id] ||= slice_on_object.build_memory_slice(data_slice.slices[slice_id])
        @memory_slice_overrides[slice_id].set_slice(slice_on_object, **slice_definition.symbolize_keys)
      end

      def reset(slice_on)
        slice_on_object = definition_object_for(slice_on)
        slice_id = slice_on_object.slice_id
        return false unless @memory_slice_overrides[slice_id]
        to_remove = @memory_slice_overrides[slice_id].reset(slice_on_object.id)
        @memory_slice_overrides.delete(slice_id) if to_remove
        true
      end

      # = Applying slices

      # @param facts [Array<Fact>]
      def apply_on(facts)
        @memory_slice_overrides.values.inject(facts.dup) do |selected_facts, memory_slice_override|
          memory_slice_override.apply_on(selected_facts)
        end
      end

      def for_cube_name(cube_name)
        @cube_name_scope = cube_name
        return_value = yield self
        @cube_name_scope = nil
        return_value
      end

      # @return [Array<String>]
      def keys_for_cube_scope
        return keys unless @cube_name_scope
        keys.select do |slice_id|
          slice_object = @memory_slice_overrides[slice_id] || @data_slice.slices[slice_id]
          slice_object.respond_to?(:cube_name) ? slice_object.cube_name == @cube_name_scope : true
        end
      end

    end
  end
end
