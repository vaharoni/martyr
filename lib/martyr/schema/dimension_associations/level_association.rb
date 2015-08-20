module Martyr
  module Schema
    class LevelAssociation

      attr_accessor :level, :fact_key, :fact_alias
      delegate :name, :to_i, :level_and_above, to: :level

      # @param level [BaseLevelDefinition]
      def initialize(level, fact_key: nil, fact_alias: nil)
        @level = level
        @fact_key = fact_key || level.fact_key
        @fact_alias = fact_alias || level.fact_alias
      end

    end
  end
end