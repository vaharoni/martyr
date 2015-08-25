module Martyr
  module Runtime
    class BaseLevelScope
      include Martyr::Level
      include Martyr::LevelComparator

      attr_accessor :level
      attr_reader :collection
      delegate :name, :dimension_name, :query?, :degenerate?, :to_i, to: :level

      def initialize(collection, level)
        @collection = collection
        @level = level
        @cache = nil
      end

    end
  end
end