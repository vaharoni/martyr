module Martyr
  module Runtime
    class PlainDimensionMemorySlice

      attr_reader :dimension_definition, :data_slice

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
            dimension_bus.level_scope(level.id).recursive_lookup_up()
            dimension_bus.level_scope(data_slice.level_id).recursive_lookup_down(element[@memory_level.id], level: @sub_cube_dimension_slice)

          when 1

        end
      end

    end
  end
end
