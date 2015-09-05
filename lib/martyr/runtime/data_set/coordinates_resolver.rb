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
    #                                                                                taken from the dimension itself - not the ones stored
    #                                                                                in the element facts.
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
        levels_in_memory_grain.each do |level_scope|
          case sub_cube_slice.compare_level_with_grain(level_scope)
            when nil, 0, -1
              # Either:
              #   Dimension does not exist in the sub cube slice
              #   Levels are the same
              #   The level in the sub cube slice is higher than `level_scope`
              @strategies << FromElementStrategy.new(level_scope.id)
            when 1
              # The level in the sub cube slice is lower than `level_scope`
              level_in_slice = sub_cube_slice.dimension_for_level(level_scope.id).level
              @strategies << FromSubCubeWhileRespectingParentElementStrategy.new(level_scope, level_in_slice)
          end
        end
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

      end

      class FromSubCubeWhileRespectingParentElementStrategy
        def initialize(memory_level, sub_cube_level)
          @memory_level = memory_level
          @sub_cube_level = sub_cube_level
        end

        # TODO: add merging capability for slice.
        # Because what happens when you have slice1: without: [5] and slice2: with: [7]. You have to merge them!
        def execute(element)
          sub_cube_level_values = @memory_level.recursive_value_lookup_down(element[@memory_level.id], level: @sub_cube_level)
          { @sub_cube_level => { 'with' => arr } }
        end
      end

      # TODO: implement
      class MergeMetricSliceStrategy

      end
    end
  end
end