module Martyr
  module Schema
    class LevelAssociationCollection < HashWithIndifferentAccess
      include Martyr::Schema::IsLevelCollection

      delegate :dimension_definition, to: :dimension

      # @param level [String, Symbol]
      # @return [LevelAssociation]
      def has_dimension_level(level: , **args)
        level_object = dimension_definition.levels[level]
        raise Schema::Error.new("Could not find level `#{level}` for dimension #{dimension_name}") unless level_object.present?
        level_association = LevelAssociation.new(self, level_object, **args)
        register level_association
      end

      def level_and_above_supported(level_name)
        all_level_names = find_level(level_name).level_and_above_full.map(&:name)
        to_hash.slice(*all_level_names)
      end

      def level_and_below_supported(level_name)
        all_level_names = find_level(level_name).level_and_below_full.map(&:name)
        to_hash.slice(*all_level_names)
      end
    end
  end
end