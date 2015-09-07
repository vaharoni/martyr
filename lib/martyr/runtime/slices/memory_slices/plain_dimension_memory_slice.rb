module Martyr
  module Runtime
    class PlainDimensionMemorySlice

      attr_reader :dimension_definition, :data_slice, :dimension_bus

      # @param dimension_definition [PlainDimensionDefinition]
      # @param dimension_bus [QueryContext] allowing translation from dimension level definition to dimension level scope
      # @option data_slice [PlainDimensionDataSlice, nil] data slice from sub cube if exists
      def initialize(dimension_definition, dimension_bus, data_slice = nil)
        @dimension_definition = dimension_definition
        @dimension_bus = dimension_bus
        @data_slice = data_slice
      end

      # @param level [BaseLevelDefinition]
      def set_slice(level, **options)
        @level = level
        new_slice_definition = PlainDimensionLevelSliceDefinition.new(options)
        if data_slice.blank?
          @slice_definition = new_slice_definition
          return
        end

        case data_slice.level.to_i <=> level.to_i
          when 0
            @slice_definition = data_slice.merge(new_slice_definition)
          when -1
            # The level in the data slice is higher (less detailed, lower index) than `level`
            # Example:
            #   data slice:         'customers.country' => 'USA'
            #   requested slice:    'customers.last_name' => 'White'
            data_slice_level_scope = dimension_bus.level_scope(data_slice.level.id)
            drill_down_values = data_slice_level_scope.recursive_lookup_down(data_slice_level_scope.all, level: level)
            @slice_definition = PlainDimensionLevelSliceDefinition.new(with: drill_down_values).merge(new_slice_definition)
          when 1
            # The level in the data slice is lower (more detailed, higher index) than `level`
            # Example:
            #   data slice:         'customers.city' => ['San Francisco', 'Vancouver']
            #   requested slice:    'customers.country' => 'USA'
            level_scope = dimension_bus.level_scope(level.id)
            drill_down_values = level_scope.recursive_lookup_down(level_scope.all, level: level)
            @slice_definition = PlainDimensionLevelSliceDefinition.new(with: drill_down_values).merge(new_slice_definition)
        end
      end

    end
  end
end
