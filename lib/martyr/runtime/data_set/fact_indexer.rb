module Martyr
  module Runtime
    class FactIndexer

      attr_reader :sub_cube, :facts

      def initialize(sub_cube, facts)
        @sub_cube = sub_cube
        @facts = facts
        @indices = {}
      end

      def facts_by(*level_keys_arr)
        return @indices[level_keys_arr] if @indices[level_keys_arr]
        arr = facts.group_by do |fact|
          level_keys_arr.map{|key| fact.fetch(key)}
        end.map do |index_key, arr|
          [index_key, FactSet.new(sub_cube, arr)]
        end
        @indices[level_keys_arr] = Hash[arr]
      end
    end
  end
end
