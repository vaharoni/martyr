module Martyr
  module LevelComparator

    # @param level1 [LevelAssociation, LevelDefinition nil]
    # @param level2 [LevelAssociation, LevelDefinition, nil]
    # @return [LevelAssociation, LevelDefinition, nil]
    #   - nil if both nil
    #   - level1 if level1 is "equal level" or "lower level" than level2, or if level2 is nil
    #   - level2 if level2 is "lower level" than level1 or if level1 is nil
    def more_detailed_level(level1, level2)
      return nil unless level1 or level2
      return level1 || level2 unless level1 and level2
      return level1 if level1.to_i >= level2.to_i
      level2
    end


    # @param level_definition [LevelDefinition]
    # @param level_association_collection [LevelAssociationCollection]
    # @return [LevelAssociation, nil] finds the highest supported level in the cube that is equal or below level_definition
    def find_common_denominator_level(level_definition, level_association_collection)
      common_denominator = level_definition.level_and_below_full.find{|definition| level_association_collection[definition.name] }
      level_association_collection[common_denominator.try(:name)]
    end

  end
end