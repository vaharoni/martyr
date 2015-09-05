module Martyr
  module Runtime

    # The objective of this class is to help resolve the coordinates of an element.
    #
    # Here is a table of the possible cases:
    #
    #  Sub Cube Slice                                      Elements by               Result
    #  {'customers.city' => {with: 'Boston', 'Paris'}}     'media_types.name'        The sub cube slice + the current media type
    #  {'customers.city' => {with: 'Boston', 'Paris'}}     'customers.city'          The current element city
    #  {'customers.city' => {with: 'Boston', 'Paris'}}     'customers.last_name'     The current element last name
    #  {'customers.city' => {with: 'Boston', 'Paris'}}     'customers.country'       All the cities in the current element country,
    #                                                                                taken from the dimension itself, that overlap
    #                                                                                with the cities in the sub cube slice.
    #
    class CoordinatesResolver

      # @param sub_cube_slice [SubCubeSlice] the slice of the sub cube
      # @param levels_in_memory_grain [Array<BaseLevelScope>]
      #   This can be different than BOTH the grain in the query context AND the grain in the sub cube.
      #   For example:
      #     Query context grain:    'customers.city'
      #     Sub cube grain:         'customers.last_name'  for example when 'customers.city' does not exist in the sub cube
      #     Memory context grain:   'customers.country'    for example when pivoting Country on rows
      #
      def initialize(sub_cube_slice, levels_in_memory_grain)
        @strategies = []

        # First we handle all dimensions that are both in the memory grain and in the sub cube slice
        levels_in_memory_grain.each do |level_scope|
          case sub_cube_slice.compare_level_with_grain(level_scope)
            when nil, 0, -1
              # Either:
              #   Dimension does not exist in the sub cube slice
              #   Levels are the same
              #   The level in the sub cube slice is higher than `level_scope`
              @strategies << FromElementStrategy.new(level_scope.id)
            when 1
              # The level in the sub cube slice is lower than level_scope`
              sub_cube_dimension_slice = sub_cube_slice.dimension_slice_for_level(level_scope.id)
              @strategies << MergeWithSubCubeDimensionSlice.new(level_scope, sub_cube_dimension_slice)
          end
        end

        # Then we handle all the other slices (dimensions + metrics) in the sub cube
        sub_cube_slice.slices.except(*levels_in_memory_grain.map(&:dimension_name)).each do |slice_on, slice_object|
          @strategies << FromSubCubeStrategy.new(slice_object.to_hash)
        end
      end

      def resolve(element)
        @strategies.inject({}) {|coords_hash, strategy| coords_hash.merge!(strategy.execute(element))}
      end

      class FromElementStrategy
        def initialize(level_id)
          @level_id = level_id
        end

        def execute(element)
          { @level_id => {with: element[@level_id]} }
        end
      end

      class FromSubCubeStrategy
        def initialize(slice_hash)
          @slice_hash = slice_hash
        end

        def execute(_element)
          @slice_hash
        end
      end

      class MergeWithSubCubeDimensionSlice
        def initialize(memory_level, sub_cube_dimension_slice)
          @memory_level = memory_level
          @sub_cube_dimension_slice = sub_cube_dimension_slice
        end

        def execute(element)
          dimension_values_for_sub_cube_level = @memory_level.recursive_value_lookup_down(element[@memory_level.id], level: @sub_cube_dimension_slice)
          merged_slice = PlainDimensionSliceDefinition.new(with: dimension_values_for_sub_cube_level).merge(@sub_cube_dimension_slice.slice_definition)
          merged_slice.to_hash
        end
      end
    end
  end
end
