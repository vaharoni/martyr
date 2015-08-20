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
        to_a[level_index(level_name) + 1..-1].map(&:second).find{|level| level.query?}
      end

      # @param level_name [String, Symbol]
      # @return [Array<BaseLevelDefinition>] the provided level and all the levels above it
      def level_and_above(level_name)
        values[0..level_index(level_name)]
      end
    end
  end
end