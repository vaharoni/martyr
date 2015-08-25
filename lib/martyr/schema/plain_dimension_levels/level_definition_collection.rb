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
    end
  end
end