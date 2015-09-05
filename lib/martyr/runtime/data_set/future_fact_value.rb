module Martyr
  module Runtime
    class FutureFactValue
      attr_reader :fact_record, :level, :fact_key_value, :active_record
      delegate :dimension_bus, to: :fact_record

      # @param fact_record [Fact]
      # @param level [BaseLevelDefinition] the level that needs to be fetched
      # @param fact_key_value [String, Integer] if provided, this means the fact has direct association with the level,
      #   and the value simply needs to be fetched from the dimension.
      def initialize(fact_record, level, fact_key_value = nil)
        @level = level
        @fact_record = fact_record
        @fact_key_value = fact_key_value
      end

      def inspect
        value_loaded? ? @value.inspect : '?'
      end

      def value
        return @value if value_loaded?
        if fact_key_value
          @active_record = dimension_bus.fetch_supported_query_level_record(level.id, fact_key_value)
          @value = level.record_value(@active_record)
        else
          value = dimension_bus.fetch_unsupported_level_value(level.id, fact_record)
          if level.degenerate?
            @value = value
          else
            @active_record = value
            @value = level.record_value(@active_record)
          end
        end
        @value_loaded = true
        @value
      end

      def value_loaded?
        !!@value_loaded
      end
    end
  end
end