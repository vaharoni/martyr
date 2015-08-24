module Martyr
  module Runtime
    class BaseLevelScope
      include Martyr::Level
      include Martyr::LevelComparator

      attr_accessor :level
      attr_reader :collection
      delegate :name, :dimension_name, :supported?, :query?, :degenerate?, :fact_key, :fact_alias, :to_i, to: :level

      def initialize(collection, level)
        @collection = collection
        @level = level
        @cache = nil
      end

      def id
        "#{dimension_name}.#{name}"
      end

      def common_denominator_with_cube
        @_common_denominator_with_cube ||= find_common_denominator_level(self, collection.supported_levels)
      end

      def level_above
        return @_level_above if @_level_above
        raise Query::Error.new("`#{dimension_name}`: Cannot find level above `#{name}`") unless level.level_above
        @_level_above = collection.find_or_nil(level.level_above.name)
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