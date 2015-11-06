module Martyr
  module Runtime
    class BaseLevelScope
      include Martyr::Level
      include Martyr::LevelComparator

      attr_accessor :level
      attr_reader :collection
      delegate :level_definition, :name, :dimension_name, :query?, :degenerate?, :to_i, to: :level
      delegate :fact_key, :fact_alias, to: :level_definition

      def initialize(collection, level)
        @collection = collection
        @level = level
        @cache = nil
      end

    end
  end
end
