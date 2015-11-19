module Martyr
  module Runtime
    class SubCube

      include Martyr::LevelComparator
      include Martyr::Translations
      include Martyr::Runtime::FactFillerStrategies

      attr_reader :query_context, :cube, :fact_scopes, :metrics, :grain
      delegate :combined_sql, :pretty_sql, :test, :select_keys, to: :fact_scopes

      # TODO: supported_* methods are delegated to the grain, but there are equivalent methods in the cube that mean
      #       something else and sometimes needed. #select_supported_level_ids, for instance, is relying on those
      #       methods in the cube, not the grain.
      #       This is confusing.
      delegate :cube_name, :dimension_associations, :select_supported_level_ids, to: :cube
      delegate :supported_level_associations, :supported_level_definitions, :has_association_with_level?, to: :grain

      delegate :find_metric, :metric_ids, :metric_objects, :built_in_metrics, :custom_metrics, to: :metrics
      delegate :facts, to: :fact_indexer
      delegate :definition_from_id, to: :query_context

      alias_method :dimension_bus, :query_context

      # @param cube [Martyr::Cube]
      def initialize(query_context, cube)
        @query_context = query_context
        @cube = cube
        @fact_scopes = cube.build_fact_scopes

        @metrics = QueryMetrics.new(self)
        @grain = SubCubeGrain.new(self)
      end

      def inspect
        to_hash.inspect
      end

      def to_hash
        {cube_name => {metrics: metrics.to_a, grain: grain.to_a}}
      end

      def dimension_definitions
        cube.supported_dimension_definitions
      end

      # @return [DimensionReference, LevelAssociation]
      def association_from_id(id)
        with_standard_id(id) do |x, y|
          return dimension_associations[x].try(:levels).try(:[], y) if x and y
          dimension_associations[x]
        end
      end

      def common_denominator_level_association(level_id, prefer_query: false)
        @_common_denominator_level_association ||= {}
        return @_common_denominator_level_association[level_id] if @_common_denominator_level_association[level_id]

        level = definition_from_id(level_id)
        dimension_association = dimension_associations.find_dimension_association(level.dimension_name)
        level = find_common_denominator_level(level, dimension_association.level_objects, prefer_query: prefer_query)
        return nil unless level

        @_common_denominator_level_association[level_id] = dimension_association.levels[level.name]
      end

      # = Definitions

      def set_metrics(metrics_arr)
        return unless metrics_arr.present?
        metrics_arr.each do |metric_id|
          @metrics.add_metric(metric_id)
        end
      end

      def set_all_metrics
        metrics.add_all
      end

      def set_grain(grain_arr)
        select_supported_level_ids(grain_arr).each do |level_id|
          @grain.add_granularity(level_id)
        end
      end

      def lowest_level_ids_in_grain
        grain.level_ids
      end

      # TODO: remove
      # def set_grain_to_all_if_empty
      #   grain.set_all_if_empty
      # end

      # @param data_slice [DataSlice] that is scoped to the cube
      def decorate_all_scopes(data_slice)
        grain.add_to_select(fact_scopes)
        metrics.add_to_select(fact_scopes)
        data_slice.add_to_where(fact_scopes, dimension_bus)
        grain.add_to_group_by(fact_scopes)
      end

      # = Running

      # @param memory_slice [MemorySlice]
      # @option levels [Array<String, Martyr::Level>] array of level IDs or any type of level to group facts by.
      #   Default is all levels in the query context.
      # @option metrics [Array<String, BaseMetric>] array of metric IDs or metric objects to roll up in the elements.
      def elements(memory_slice, levels: nil, metrics: nil)
        element_locator_for(memory_slice, metrics: metrics).all(sanitize_levels(levels: levels).map(&:id))
      end

      def element_locator_for(memory_slice, metrics: nil)
        ElementLocator.new memory_slice: memory_slice, metrics: sanitize_metrics(metrics: metrics),
          fact_indexer: fact_indexer, restrict_level_ids: query_context.level_ids_and_above_for(sanitize_levels.map(&:id) + cube.default_grain)
      end

      def fact_indexer
        @fact_indexer ||= FactIndexer.new(self, grain.null? ? [] : fact_scopes.run.map { |hash| Fact.new(self, hash) })
      end

      # @option metrics [Array<String, BaseMetric>] array of metric IDs or metric objects
      def sanitize_metrics(metrics: nil)
        metric_ids = Array.wrap(metrics).map { |x| to_id(x) }.presence || self.metrics.metric_ids
        metric_ids = metric_ids & self.metrics.metric_ids
        metric_ids.map {|id| query_context.metric(id) }
      end

      # @option levels [Array<String, Martyr::Level>] array of level IDs or any type of level to group facts by.
      #   Default is all levels in grain
      # @return [Array<String, BaseLevelScope>]
      def sanitize_levels(levels: nil)
        level_ids = levels.nil? ? query_context.level_ids_in_grain : Array.wrap(levels).map { |x| to_id(x) }
        level_ids = select_supported_level_ids(level_ids)
        query_context.levels_and_above_for(level_ids)
      end

    end
  end
end
