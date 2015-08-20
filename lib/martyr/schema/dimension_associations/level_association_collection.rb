module Martyr
  module Schema
    class LevelAssociationCollection < HashWithIndifferentAccess
      include Martyr::Schema::IsLevelCollection

      # @param level [String, Symbol]
      # @return [LevelAssociation]
      def has_dimension_level(level: , **args)
        level_object = dimension_definition.levels[level]
        raise Schema::Error.new("Could not find level `#{level}` for dimension #{dimension_name}") unless level_object.present?
        level_association = LevelAssociation.new(level_object, **args)
        register level_association
      end

      # @return [Hash] with only the supported levels above the one provided
      def level_and_above(level_name)
        all_level_names = find_level(level_name).level_and_above.map(&:name)
        to_hash.slice(*all_level_names)
      end

    end
  end
end