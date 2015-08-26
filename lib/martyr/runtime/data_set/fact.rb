module Martyr
  module Runtime
    class Fact < HashWithIndifferentAccess
      include Martyr::LevelComparator

      attr_reader :sub_cube
      delegate :dimension_bus, to: :sub_cube

      def initialize(sub_cube, query_result_hash)
        @sub_cube = sub_cube
        hash = {}
        sub_cube.supported_level_definitions.each do |level_definition|
          if sub_cube.supports_level?(level_definition.id)
            level_association = sub_cube.association_from_id(level_definition.id)
            fact_key_value = query_result_hash.fetch(level_association.fact_alias)
            if level_association.degenerate?
              value = fact_key_value
            else
              value = Future.new(self, level_definition, fact_key_value)
            end
          else
            value = Future.new(self, level_definition)
          end
          hash[level_definition.id] = value
        end
        merge!(hash)
      end

      alias_method :hash_fetch, :fetch

      def fetch(key)
        value = super(key)
        value.is_a?(Future) ? value.value : value
      end
      alias_method :[], :fetch

      def record_for(level_id)
        future = hash_fetch(level_id)
        return nil unless future.is_a?(Future)
        future.active_record
      end

      class Future
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
end