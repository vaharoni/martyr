module Martyr
  module Runtime
    class MemorySlice
      include Martyr::Translations

      attr_accessor :data_slice, :memory_slice_overrides
      delegate :definition_resolver, :definition_object_for, to: :data_slice

      def initialize(data_slice)
        @data_slice = data_slice
        @memory_slice_overrides = ScopeableSliceData.new
      end

      def inspect
        to_hash.inspect
      end

      def override_values
        memory_slice_overrides.values
      end

      def keys
        (override_values.flat_map(&:keys) + data_slice.keys).uniq
      end

      def to_hash
        overrides = override_values.inject({}) {|h, slice| h.merge! slice.to_hash}
        data_slice.to_hash.merge!(overrides).slice(*keys)
      end

      # @param slice_on [String]
      # @param slice_definition [Hash]
      def slice(slice_on, slice_definition)
        definition_resolver.validate_slice_on!(slice_on)
        slice_on_object = definition_object_for(slice_on)
        slice_id = slice_on_object.slice_id
        memory_slice_overrides[slice_id] ||= slice_on_object.build_memory_slice(data_slice.slices[slice_id])
        memory_slice_overrides[slice_id].set_slice(slice_on_object, **slice_definition.symbolize_keys)
      end

      # = Applying slices

      # @param facts [Array<Fact>]
      def apply_on(facts)
        override_values.inject(facts.dup) do |selected_facts, memory_slice_override|
          memory_slice_override.apply_on(selected_facts)
        end
      end

      # @param cube_name [String]
      # @return [MemorySlice] new object with new DataSlice and ScopeableDataSliceData objects, both set to be scoped
      #   to cube_name
      def for_cube_name(cube_name)
        dup.for_cube_name!(cube_name)
      end

      # @param cube_name [String]
      # @return [MemorySlice] same object with new DataSlice and ScopeableDataSliceData objects, both set to be scoped
      #   to cube_name
      def for_cube_name!(cube_name)
        self.data_slice = data_slice.for_cube_name(cube_name)
        self.memory_slice_overrides = memory_slice_overrides.scope(cube_name)
        self
      end

    end
  end
end
