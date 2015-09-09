module Martyr
  class LevelDefinitionsByDimension

    attr_reader :dimensions

    # @param levels [Martyr::Level, Array<Martyr::Level>]
    def initialize(levels = nil)
      @dimensions = {}
      Array.wrap(levels).each{|x| add_level(x)}
    end

    # @param level [Martyr::Level]
    def add_level(level)
      @dimensions[level.dimension_name] ||= {}
      @dimensions[level.dimension_name][level.id] = level
    end

    def lowest_levels
      dimensions.values.map do |levels_hash|
        levels_hash.values.max_by(&:to_i)
      end
    end
  end
end
