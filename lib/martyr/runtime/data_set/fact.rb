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

      # @param id [String] either metric id or level id
      def fetch(id)
        value = hash_fetch(fully_qualify_id(id))
        value.is_a?(FutureFactValue) ? value.value : value
      end
      alias_method :[], :fetch

      # Similar to fetch, but returns the original fact_key_value if such existed for the level
      def fact_key_for(level_id)
        value = hash_fetch(level_id)
        value.is_a?(FutureFactValue) ? (value.fact_key_value || value.value) : value
      end

      # Similar to fetch, but returns the active record object if such existed for the level
      def record_for(level_id)
        value = hash_fetch(level_id)
        value.is_a?(FutureFactValue) ? (value.active_record || value.value) : value
      end

      private

      def value_by_levels_hash
        hash = {}
        sub_cube.supported_level_definitions.each do |level_definition|
          if sub_cube.has_association_with_level?(level_definition.id)
            level_association = sub_cube.association_from_id(level_definition.id)
            fact_key_value = raw.fetch(level_association.fact_alias)
            if level_association.degenerate?
              # The value is stored in the fact. No query needed.
              value = fact_key_value
            else
              # The primary key is stored in the fact and we need to retrieve the string value from the dimension.
              value = FutureFactValue.new(self, level_definition, fact_key_value)
            end
          else
            # We don't have a direct connection to the level - we can access it through traversing the dimension
            # hierarchy starting at a lower level.
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

      def fully_qualify_id(id)
        with_standard_id(id) do |dimension_or_cube_or_metric, level_or_metric|
          level_or_metric ? id : "#{sub_cube.cube_name}.#{dimension_or_cube_or_metric}"
        end
      end

    end
  end
end
