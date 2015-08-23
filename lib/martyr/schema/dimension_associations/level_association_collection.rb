module Martyr
  module Schema
    class LevelAssociationCollection < HashWithIndifferentAccess
      include Martyr::LevelCollection

      # @param level [String, Symbol]
      # @return [LevelAssociation]
      def has_dimension_level(level: , **args)
        level_definition = dimension_definition.levels[level]
        raise Schema::Error.new("Could not find level `#{level}` for dimension #{dimension_name}") unless level_definition
        level_association = LevelAssociation.new(self, level_definition, **args)
        register level_association
      end
    end
  end
end