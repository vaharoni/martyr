module Martyr
  module Runtime
    class FactIndexer

      attr_reader :sub_cube, :facts

      def initialize(sub_cube, facts)
        @sub_cube = sub_cube
        @facts = facts
        @indices = {}
      end

      def elements_by(*level_keys_arr)
        return @indices[level_keys_arr].values if @indices[level_keys_arr]
        arr = facts.group_by do |fact|
          level_keys_arr.map{|key| fact.fetch(key)}
        end.map do |index_key, facts_arr|
          grain_arr = level_keys_arr.each_with_index.map {|level_id, i| [level_id, index_key[i]]}
          [index_key, Element.new(Hash[grain_arr], facts_arr)]
        end
        @indices[level_keys_arr] = Hash[arr]
        @indices[level_keys_arr].values
      end
    end
  end
end
