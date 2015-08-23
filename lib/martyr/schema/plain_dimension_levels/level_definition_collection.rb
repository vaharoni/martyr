module Martyr
  module Schema
    class LevelDefinitionCollection < HashWithIndifferentAccess
      include Martyr::LevelCollection

      def degenerate_level(*args)
        register DegenerateLevelDefinition.new(self, *args)
      end

      def query_level(*args)
        register QueryLevelDefinition.new(self, *args)
      end

      # @return [BaseLevelDefinition]
      def level_above(level_name)
        above_index = level_index(level_name) - 1
        return nil if above_index < 0
        values[above_index]
      end
    end
  end
end