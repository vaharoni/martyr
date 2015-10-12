module Martyr
  module Runtime
    class FactIndexer

      attr_reader :sub_cube, :facts
      delegate :dimension_bus, :cube_name, to: :sub_cube

      def initialize(sub_cube, facts)
        @sub_cube = sub_cube
        @facts = facts
        @indices = {}
      end

      # @param memory_slice [MemorySlice] scoped to the current cube
      # @param level_ids [Array<String>] level ids used to group facts by
      # @return [Array<Element>] creates an array of elements. Each elements holds multiple facts based on
      #   level_keys_arr.
      #
      # Example:
      #   Consider facts with the following grain:
      #        media_types.name    genres.name       customers.country     Metric 1      Metric 2
      #     1  MPEG audio file     Rock              USA                   100           20
      #     2  MPEG audio file     Pop               USA                   76            32
      #     3  MPEG audio file     Jazz              USA                   98            16
      #     4  AAC audio file      Rock              USA                   57            25
      #     5  AAC audio file      Pop               USA                   98            72
      #     6  AAC audio file      Jazz              USA                   34            18
      #
      # Running `elements_by 'genres.name'` will return 3 elements:
      #     genres.name     Contained facts
      #     Rock            1,4
      #     Pop             2,5
      #     Jazz            3,6
      #
      # In addition, each element will have the metrics, rolled-up based on their roll-up function
      #
      def elements_by(memory_slice, level_ids)
        elements_hash(memory_slice, level_ids).values
      end

      # @param coordinates [Coordinates]
      # @return [Element] that resides in the provided coordinates
      def get_element(coordinates)
        elements_hash(coordinates.memory_slice, coordinates.grain_hash.keys)[coordinates.grain_hash.values]
      end

      private

      # @return [Hash] { element_key => Element }
      #   where element_key is array of values for levels in the same order of level_ids.
      def elements_hash(memory_slice, level_ids)
        sorted_level_ids = level_ids.sort
        index_key = {slice: memory_slice.to_hash, levels: sorted_level_ids}
        return @indices[index_key] if @indices[index_key]

        arr = memory_slice.apply_on(facts).group_by do |fact|
          level_ids.map{|id| fact.fetch(id)}
        end.map do |element_key, facts_arr|
          grain_arr = element_key.each_with_index.map {|value, i| [level_ids[i], value]}
          coordinates = Coordinates.new(Hash[grain_arr], memory_slice.to_hash)
          [element_key, Element.new(coordinates, facts_arr)]
        end
        @indices[index_key] = Hash[arr]
      end
    end
  end
end
