module Martyr
  module Runtime
    class SubCube

      include Martyr::LevelComparator
      include Martyr::Translations

      attr_reader :query_context, :cube, :fact_scopes, :metrics, :grain, :sub_cube_slice
      delegate :combined_sql, :pretty_sql, :test, :select_keys, to: :fact_scopes
      delegate :cube_name, :dimension_associations, to: :cube
      delegate :supported_level_associations, :supported_level_definitions, :supports_level?, to: :grain
      delegate :facts, :facts_by, to: :fact_indexer

      alias_method :dimension_bus, :query_context

      # @param cube [Martyr::Cube]
      def initialize(query_context, cube)
        @query_context = query_context
        @cube = cube
        @fact_scopes = cube.build_fact_scopes

        @metrics = QueryMetrics.new(self)
        @grain = SubCubeGrain.new(self)
        @sub_cube_slice = SubCubeSlice.new(self)
      end

      def inspect
        "#{cube_name}: {#{metrics.inspect_part}, #{sub_cube_slice.inspect_part}, #{grain.inspect_part}}"
      end

      def dimension_definitions
        cube.supported_dimension_definitions
      end

      # @return [BaseMetric, DimensionReference, BaseLevelDefinition]
      def definition_from_id(id)
        with_standard_id(id) do |x, y|
          return dimension_definitions[x].try(:levels).try(:[], y) if x and y
          metrics[x] || dimension_definitions[x]
        end
      end

      # @return [DimensionReference, LevelAssociation]
      def association_from_id(id)
        with_standard_id(id) do |x, y|
          return dimension_associations[x].try(:levels).try(:[], y) if x and y
          dimension_associations[x]
        end
      end

      def common_denominator_level_association(level_id)
        @_common_denominator_level_association ||= {}
        return @_common_denominator_level_association[level_id] if @_common_denominator_level_association[level_id]

        level = definition_from_id(level_id)
        dimension_association = dimension_associations.find_dimension_association(level.dimension_name)
        level = find_common_denominator_level(level, dimension_association.level_objects)
        return nil unless level

        @_common_denominator_level_association[level_id] = dimension_association.levels[level.name]
      end

      # = Definitions

      def set_metrics(metrics_arr)
        if metrics_arr.empty?
          metrics.add_all
        else
          metrics_arr.each do |metric_id|
            @metrics.add_metric(metric_id)
          end
        end
      end

      def set_slice(slice_hash)
        slice_hash.each do |slice_on, slice_definition|
          @sub_cube_slice.slice(slice_on, slice_definition)
        end
      end

      def set_grain(grain_arr)
        grain_arr.each do |level_id|
          @grain.add_granularity(level_id)
        end
      end

      def set_defaults_and_dependencies
        sub_cube_slice.add_to_grain(grain)
        grain.set_all_if_empty
        grain.nullify_scope_if_null(fact_scopes)
      end

      def slice_all_scopes
        grain.add_to_select(fact_scopes)
        metrics.add_to_select(fact_scopes)
        sub_cube_slice.add_to_where(fact_scopes)
        grain.add_to_group_by(fact_scopes)
      end

      # = Running

      def fact_indexer
        @fact_indexer ||= FactIndexer.new(self, grain.null? ? [] : fact_scopes.run.map { |hash| Fact.new(self, hash) })
      end

      def fact_sets
        facts_by *grain.level_ids
      end

    end
  end
end
