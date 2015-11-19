module Martyr
  module Runtime
    class Fact < Hash
      include Martyr::LevelComparator
      include Martyr::Translations

      attr_reader :sub_cube, :raw
      delegate :dimension_bus, to: :sub_cube

      def initialize(sub_cube, query_result_hash)
        @sub_cube = sub_cube
        @raw = query_result_hash
        merge_value_by_levels_hash
        merge_built_in_metrics_hash
        merge_custom_metrics_hash
      end

      alias_method :hash_fetch, :fetch

      # @param id [String] either metric id or level id
      def fetch(id)
        value = hash_fetch(fully_qualify_id(id))
        value.is_a?(FutureFactValue) || value.is_a?(FutureMetric) ? value.value : value
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

      def load
        keys.each{|key| fetch(key)}
        self
      end

      private

      def merge_value_by_levels_hash
        sub_cube.fact_levels_filler_hash.each do |level_id, filler|
          store level_id, filler.value(self)
        end
      end

      def merge_built_in_metrics_hash
        sub_cube.built_in_metrics.each do |metric|
          store metric.id, metric.extract(self)
        end
      end

      # This has to occur after merging the built_in_metrics_hash so that the user custom code can fetch
      # existing metrics. We merge them one after the other so custom metrics can depend on one another.
      def merge_custom_metrics_hash
        sub_cube.custom_metrics.each do |metric|
          store metric.id, FutureMetric.wrap(self, metric, :extract)
        end
      end

      def fully_qualify_id(id)
        with_standard_id(id) do |dimension_or_cube_or_metric, level_or_metric|
          level_or_metric ? id : "#{sub_cube.cube_name}.#{dimension_or_cube_or_metric}"
        end
      end

      private

      def method_missing(method, *args, &block)
        return fetch(method) if has_key? fully_qualify_id(method)
        super
      end

    end
  end
end
