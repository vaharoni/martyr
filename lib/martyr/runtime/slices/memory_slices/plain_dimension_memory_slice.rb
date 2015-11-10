module Martyr
  module Runtime
    class PlainDimensionMemorySlice

      include Martyr::Runtime::HasScopedLevels

      attr_reader :dimension_definition, :data_slice, :levels
      delegate :keys, to: :levels

      # @param dimension_definition [PlainDimensionDefinition]
      # @option data_slice [PlainDimensionDataSlice, nil] data slice from sub cube if exists
      def initialize(dimension_definition, data_slice = nil)
        @dimension_definition = dimension_definition
        @data_slice = data_slice
        @levels = {}
      end

      def to_hash
        arr = scoped_levels.values.sort_by{|slice| slice.level.to_i}.inject({}){|h, slice| h.merge!(slice.to_hash) }
        Hash[arr]
      end

      def set_slice(level, **options)
        new_slice_definition = PlainDimensionLevelSliceDefinition.new(level: level, **options)
        if data_slice.try(:get_slice, level.id).blank?
          @levels[level.id] = new_slice_definition
        else
          @levels[level.id] = new_slice_definition.merge(data_slice.get_slice(level.id))
        end
      end

      # @return [PlainDimensionLevelSliceDefinition]
      def get_slice(level_id)
        scoped_levels[level_id]
      end

      def apply_on(facts)
        scoped_levels.keys.inject(facts) do |selected_facts, level_id|
          selected_facts.select do |fact|
            get_slice(level_id).with.include? fact.fact_key_for(level_id)
          end
        end
      end

    end
  end
end
