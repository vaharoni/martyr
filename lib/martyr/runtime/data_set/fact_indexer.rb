module Martyr
  module Runtime
    class FactIndexer

      attr_reader :sub_cube, :facts

      def initialize(sub_cube, facts)
        @sub_cube = sub_cube
        @facts = facts
        @indices = {}
      end

      # @param memory_slice [MemorySlice] scoped to the current cube
      # @param levels_arr [Array<BaseLevelScope>] levels used to group facts by
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
      def elements_by(memory_slice, levels_arr)
        level_keys_arr = levels_arr.map(&:id)
        index_key = {slice: memory_slice.to_hash, levels: level_keys_arr}
        return @indices[index_key].values if @indices[index_key]

        arr = memory_slice.apply_on(facts).group_by do |fact|
          level_keys_arr.map{|key| fact.fetch(key)}
        end.map do |index_key, facts_arr|
          grain_arr = level_keys_arr.each_with_index.map {|level_id, i| [level_id, index_key[i]]}
          [index_key, Element.new(Hash[grain_arr], facts_arr, memory_slice )]
        end
        @indices[index_key] = Hash[arr]
        @indices[index_key].values
      end

      def get_element(slice_hash)

      end
    end
  end
end
