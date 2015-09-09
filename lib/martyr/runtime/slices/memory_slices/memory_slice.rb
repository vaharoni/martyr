module Martyr
  module Runtime
    class MemorySlice
      include Martyr::Translations

      attr_reader :data_slice, :memory_slice_overrides
      delegate :definition_resolver, :definition_object_for, to: :data_slice

      def initialize(data_slice)
        @data_slice = data_slice
        @memory_slice_overrides = {}
      end

      def inspect
        to_hash.inspect
      end

      def dup
        new_slice = self.class.new(@data_slice)
        @memory_slice_overrides.each do |slice_id, slice_object|
          new_slice.memory_slice_overrides[slice_id] = slice_object.dup
        end
        new_slice
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

      # FIXME: the #reset_* methods have a knowledge on the slice_id, which #slice delegated to the definition objects

      def reset_dimension(dimension_name)
        @memory_slice_overrides.delete(dimension_name)
      end

      def reset_level(level_id)
        level_definition = definition_object_for(level_id)
        return unless @memory_slice_overrides[level_definition.slice_id]
        should_remove_dimension = @memory_slice_overrides[level_definition.slice_id].reset(level_id)
        @memory_slice_overrides.delete(level_definition.slice_id) if should_remove_dimension
      end

      def reset_metric(metric_id)
        @memory_slice_overrides.delete(metric_id)
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
