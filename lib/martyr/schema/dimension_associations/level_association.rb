module Martyr
  module Schema
    class LevelAssociation

      attr_accessor :level, :collection, :fact_key, :fact_alias
      delegate :name, :to_i, :level_and_above_full, :level_and_below_full, to: :level

      # @param collection [LevelAssociationCollection]
      # @param level [BaseLevelDefinition]
      def initialize(collection, level, fact_key: nil, fact_alias: nil)
        @collection = collection
        @level = level
        @fact_key = fact_key || level.fact_key
        @fact_alias = fact_alias || level.fact_alias
      end

    end
  end
end