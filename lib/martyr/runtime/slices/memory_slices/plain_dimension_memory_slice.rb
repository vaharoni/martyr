module Martyr
  module Runtime
    class PlainDimensionMemorySlice

      attr_reader :dimension_definition, :data_slice, :levels

      # @param dimension_definition [PlainDimensionDefinition]
      # @option data_slice [PlainDimensionDataSlice, nil] data slice from sub cube if exists
      def initialize(dimension_definition, data_slice = nil)
        @dimension_definition = dimension_definition
        @data_slice = data_slice
        @levels = {}
      end

      def to_hash
        arr = @levels.sort_by{|_level_id, slice| slice.level.to_i}
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

    end
  end
end
