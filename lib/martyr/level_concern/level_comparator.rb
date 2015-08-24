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


    # @param level [BaseLevelScope]
    # @param supported_levels_arr [Array<Martyr::Level>] of supported levels
    # @return [Martyr::Level, nil] finds the highest supported level in the cube that is equal or below level_definition
    def find_common_denominator_level(level, supported_levels_arr)
      raise Internal::Error.new('level cannot be nil') unless level
      raise Internal::Error.new('supported_levels_arr cannot be nil') unless supported_levels_arr
      supported_index = supported_levels_arr.index_by(&:name)
      level.level_and_below_full.find{|l| supported_index[l.name] }
    end

  end
end