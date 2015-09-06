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


    # @param level_definition [BaseLevelDefinition] must be level definition so that #level_and_below performs a full search
    # @param level_associations_arr [Array<LevelAssociation>] of supported levels
    # @option prefer_query [Boolean]
    # @return [BaseLevelDefinition, nil]
    #   prefer_query is false:
    #       Finds the highest supported level in the cube that is equal or below level_definition.
    #   prefer_query is true:
    #       Finds the highest supported +query+ level in the cube that is equal or below level_definition.
    #       If no such level exists, falls back on all levels.
    #
    def find_common_denominator_level(level_definition, level_associations_arr, prefer_query: false)
      raise Internal::Error.new('level_definition must be level definition object') unless level_definition.is_a?(Schema::BaseLevelDefinition)
      raise Internal::Error.new('level_associations_arr cannot be nil') unless level_associations_arr
      supported_index = level_associations_arr.index_by(&:name)

      levels_to_consider = level_associations_arr.select(&:query?).map(&:level).presence if prefer_query
      levels_to_consider ||= level_definition.level_and_below
      levels_to_consider.find{|l| supported_index[l.name] }
    end

    # @param levels [Array<Martyr::Level>]
    # @return [Array<LevelDefinition>] lowest levels from the levels array in each dimension
    def lowest_level_of(levels)
      LevelDefinitionsByDimension.new(levels).lowest_levels
    end


  end
end
