module Martyr
  module Runtime
    class FutureFactValue
      attr_reader :fact_record, :level, :fact_key_value, :active_record
      delegate :dimension_bus, to: :fact_record

      def initialize(fact_record, level, fact_key_value = nil)
        @level = level
        @fact_record = fact_record
        @fact_key_value = fact_key_value
      end

      def inspect
        @value || '?'
      end

      def value
        return @value if @value
        if fact_key_value
          @active_record = dimension_bus.fetch_supported_query_level_record(level.id, fact_key_value)
          @value = @active_record.send(level.label)
        else
          @value = dimension_bus.fetch_unsupported_level_value(level.id, fact_record)
        end
      end
    end
  end
end