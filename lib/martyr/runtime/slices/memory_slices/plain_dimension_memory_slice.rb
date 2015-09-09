module Martyr
  module Runtime
    class PlainDimensionMemorySlice

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
        arr = @levels.values.sort_by{|slice| slice.level.to_i}.inject({}){|h, slice| h.merge!(slice.to_hash) }
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
        @levels[level_id]
      end

      # @return [Boolean] whether the slice object should be removed from the holding parent
      def reset(level_id)
        @levels.delete(level_id)
        @levels.length == 0
      end

      def apply_on(facts)
        levels.keys.inject(facts) do |selected_facts, level_id|
          selected_facts.select do |fact|
            get_slice(level_id).with.include? fact[level_id]
          end
        end
      end

    end
  end
end
