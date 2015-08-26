module Martyr
  module Runtime
    class Fact < HashWithIndifferentAccess
      include Martyr::LevelComparator
      include Martyr::Translations

      attr_reader :sub_cube, :raw
      delegate :dimension_bus, to: :sub_cube

      def initialize(sub_cube, query_result_hash)
        @sub_cube = sub_cube
        @raw = query_result_hash
        merge!(value_by_levels_hash).merge!(built_in_metrics_hash).merge!(custom_metrics_hash)
      end

      alias_method :hash_fetch, :fetch

      def fetch(key)
        value = super(key)
        value.is_a?(FutureFactValue) ? value.value : value
      end

      alias_method :[], :fetch

      def record_for(level_id)
        future = hash_fetch(level_id)
        return nil unless future.is_a?(FutureFactValue)
        future.active_record
      end

      private

      def value_by_levels_hash
        hash = {}
        sub_cube.supported_level_definitions.each do |level_definition|
          if sub_cube.supports_level?(level_definition.id)
            level_association = sub_cube.association_from_id(level_definition.id)
            fact_key_value = raw.fetch(level_association.fact_alias)
            if level_association.degenerate?
              value = fact_key_value
            else
              value = FutureFactValue.new(self, level_definition, fact_key_value)
            end
          else
            value = FutureFactValue.new(self, level_definition)
          end
          hash[level_definition.id] = value
        end
        hash
      end

      def built_in_metrics_hash
        arr = sub_cube.built_in_metrics.map do |metric|
          [metric.id, metric.extract(self)]
        end
        Hash[arr]
      end

      # This has to occur after merging the built_in_metrics_hash so that the user custom code can fetch
      # existing metrics
      def custom_metrics_hash
        arr = sub_cube.custom_metrics.map do |metric|
          [metric.id, metric.extract(self)]
        end
        Hash[arr]
      end

    end
  end
end