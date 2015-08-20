module Martyr
  module Schema
    class LevelDefinitionCollection < HashWithIndifferentAccess
      include Martyr::Schema::IsLevelCollection

      def degenerate_level(*args)
        register DegenerateLevelDefinition.new(self, *args)
      end

      def query_level(*args)
        register QueryLevelDefinition.new(self, *args)
      end

      # = Finders

      # @param level_name [String, Symbol]
      # @return [Array<BaseLevelDefinition>] the first level of type `query` below the provided level
      def query_level_below(level_name)
        values[level_index(level_name) + 1..-1].find{|level| level.query?}
      end

      # @param level_name [String, Symbol]
      # @return [Array<BaseLevelDefinition>] the provided level and all the levels above it
      def level_and_above_full(level_name)
        values[0..level_index(level_name)]
      end

      # @param level_name [String, Symbol]
      # @return [Array<BaseLevelDefinition>] the provided level and all the levels below it
      def level_and_below_full(level_name)
        values[level_index(level_name)..-1]
      end

      # @param from_level_name [String, Symbol]
      # @param to_level_name [String, Symbol]
      # @return [Array<BaseLevelDefinition>] of all levels between the two levels, including the bounds
      def levels_between(from_level_name, to_level_name)
        values[level_index(from_level_name)..level_index(to_level_name)]
      end

      # @return [BaseLevelDefinition]
      def level_above(level_name)
        values[level_index(level_name) - 1]
      end
    end
  end
end