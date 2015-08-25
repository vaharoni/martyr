module Martyr
  module Runtime
    class SubCube

      include Martyr::LevelComparator
      include Martyr::Translations

      attr_reader :query_context, :cube, :fact_scopes, :metrics, :grain, :sub_cube_slice
      delegate :combined_sql, :pretty_sql, :test, :select_keys, to: :fact_scopes
      delegate :cube_name, to: :cube

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

      def dimension_associations
        cube.dimensions
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
        level = definition_from_id(level_id)
        dimension_association = dimension_associations.find_dimension_association(level.dimension_name)
        level = find_common_denominator_level(level, dimension_association.level_objects)
        return nil unless level
        dimension_association.levels[level.name]
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

      def foreign_keys_from_facts_for(level)
        facts.map { |x| x.send level.fact_alias }
      end

      # = Running

      def facts
        raise Query::Error.new('Sub cube must be sliced before facts can be retrieved') unless sliced
        @facts ||= fact_scopes.run.map { |x| Fact.new.merge! x.slice(*select_keys) }
      end

      def elements
        @elements ||= facts.map{|x| Element.new(self, x)}
      end

      def dimensions
        dimension_scopes.values
      end

      def dimension_ids
        dimensions.map(&:id)
      end

      def levels
        @levels ||= dimensions.flat_map(&:level_objects)
      end

      def level_ids
        levels.map(&:id)
      end

    end
  end
end
