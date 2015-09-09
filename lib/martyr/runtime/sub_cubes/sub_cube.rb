module Martyr
  module Runtime
    class SubCube

      include Martyr::LevelComparator
      include Martyr::Translations

      attr_reader :query_context, :cube, :fact_scopes, :metrics, :grain
      delegate :combined_sql, :pretty_sql, :test, :select_keys, to: :fact_scopes
      delegate :cube_name, :dimension_associations, to: :cube
      delegate :supported_level_associations, :supported_level_definitions, :has_association_with_level?, to: :grain
      delegate :find_metric, :metric_ids, :built_in_metrics, :custom_metrics, to: :metrics
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
        grain_arr.each do |level_id|
          @grain.add_granularity(level_id)
        end
      end

      def set_defaults_and_dependencies
        grain.set_all_if_empty
        grain.nullify_scope_if_null(fact_scopes)
      end

      def decorate_all_scopes(data_slice)
        grain.add_to_select(fact_scopes)
        metrics.add_to_select(fact_scopes)
        data_slice.add_to_where(fact_scopes, dimension_bus)
        grain.add_to_group_by(fact_scopes)
      end

      # = Running

      def fact_indexer
        @fact_indexer ||= FactIndexer.new(self, grain.null? ? [] : fact_scopes.run.map { |hash| Fact.new(self, hash) })
      end

      # @param memory_slice [MemorySlice]
      # @option levels [Array<String, Martyr::Level>] array of level IDs or any type of level to group facts by.
      #   Default is all levels in the query context.
      # @option metrics [Array<String, BaseMetric>] array of metric IDs or metric objects to roll up in the elements.
      def elements(memory_slice, levels: nil, metrics: nil)
        level_ids = Array.wrap(levels).map { |x| to_id(x) }.presence || query_context.level_ids_in_grain
        levels = query_context.levels_and_above_for(level_ids)
        metrics = Array.wrap(metrics).map { |x| x.is_a?(String) ? definition_from_id(x) : x }.presence || self.metrics.values
        fact_indexer.elements_by(memory_slice, levels.map(&:id)).each { |element| element.rollup(*metrics) }
      end

    end
  end
end
