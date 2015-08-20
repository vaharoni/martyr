module Martyr
  module LevelComparator

    # @param level1 [LevelAssociation, nil]
    # @param level2 [LevelAssociation, nil]
    # @return [LevelAssociation, nil]
    #   - nil if both nil
    #   - level1 if level1 is "equal level" or "lower level" than level2, or if level2 is nil
    #   - level2 if level2 is "lower level" than level1 or if level1 is nil
    def more_detailed_level(level1, level2)
      return nil unless level1 or level2
      return level1 || level2 unless level1 and level2
      return level1 if level1.to_i >= level2.to_i
      level2
    end

  end
end