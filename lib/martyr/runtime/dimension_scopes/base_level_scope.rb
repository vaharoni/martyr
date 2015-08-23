module Martyr
  module Runtime
    class BaseLevelScope
      include Martyr::Level

      attr_accessor :level
      attr_reader :loaded
      delegate :name, :dimension_name, :supported?, :query?, :degenerate?, :fact_key, :fact_alias, to: :level

      def initialize(collection, level)
        @collection = collection
        @level = level
        @loaded = false
      end

      def level_above
        @_query_above ||= collection.find_or_nil(level.level_above.name)
      end

      def query_level_below
        @_query_level_below ||= collection.query_level_below(name)
      end

      def level_and_above_full
        @_level_and_above_full ||= collection.level_and_above_full(name)
      end

      def level_and_below_full
        @_level_and_below_full ||= collection.level_and_below_full(name)
      end

      # = For supported

      def level_and_above_supported
        @_level_and_above_supported ||= supported? ? collection.level_and_above_supported(name) : nil
      end

      def level_and_below_supported
        @_level_and_below_supported ||= supported? ? collection.level_and_below_supported(name) : nil
      end

    end
  end
end