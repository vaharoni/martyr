module Martyr
  module Runtime
    class QueryContext
      include Martyr::LevelComparator
      include Martyr::Translations

      attr_accessor :sub_cubes_hash, :dimension_scopes, :level_ids_in_grain
      attr_reader :data_slice
      delegate :level_scope, :level_scopes, :with_level_scope, :lowest_level_of, :lowest_level_ids_of,
        :levels_and_above_for, :level_ids_and_above_for, :level_loaded?, to: :dimension_scopes
      delegate :slice, to: :memory_slice

      def initialize
        @data_slice = DataSlice.new(self)
        @sub_cubes_hash = {}
      end

      def inspect
        "#<QueryContext grain: #{level_ids_in_grain}, memory_slice: #{memory_slice.to_hash}, data_slice: #{data_slice.to_hash}, sub_cubes: #{sub_cubes}>"
      end

      def sub_cubes
        sub_cubes_hash.values
      end

      def metrics
        sub_cubes.flat_map{|sub_cube| sub_cube.metric_objects}
      end

      def metric_ids
        metrics.map(&:id)
      end

      # @param id [String] has to be fully qualified (cube_name.metric_name)
      def metric(id)
        metric_ids_lookup[id]
      end

       # @param id [String] has to be fully qualified (cube_name.metric_name)
      def metric?(id)
        !!metric(id)
      end

      # = Grain

      def supported_level_ids
        @_supported_level_ids ||= levels_and_above_for(level_ids_in_grain).map(&:id)
      end

      def validate_slice_on!(slice_on)
        slice_on_object = definition_from_id(slice_on)
        raise Query::Error.new("Cannot find `#{slice_on}`") unless slice_on_object
        raise Query::Error.new("Cannot slice on `#{slice_on}`: it is not in the grain") if
          slice_on_object.is_a?(Martyr::Level) and !supported_level_ids.include?(slice_on)
        true
      end

      # = Memory slices

      def memory_slice
        @memory_slice ||= MemorySlice.new(data_slice)
      end

      # @return [QueryContext] for chaining
      def slice(*args)
        memory_slice.slice(*args)
        self
      end

      # = Run

      # TODO: support multiple sub cubes

      def facts
        map_reduce_sub_cubes(&:facts)
      end

      def elements(**options)
        map_reduce_sub_cubes do |sub_cube|
          memory_slice.for_cube_name(sub_cube.cube_name) do |scoped_memory_slice|
            sub_cube.elements(scoped_memory_slice, **options)
          end
        end
      end

      def pivot
        Runtime::PivotTableBuilder.new(self)
      end

      # = Dispatcher

      # @return [BaseMetric, DimensionReference, BaseLevelDefinition]
      def definition_from_id(id)
        with_standard_id(id) do |x, y|
          return dimension_scopes[x].try(:dimension_definition) || sub_cubes.first.metrics[x] if !y
          return sub_cubes_hash[x].find_metric(y) if sub_cubes_hash[x]
          dimension_scopes.find_level(id).try(:level_definition)
        end
      end

      # = As Dimension Bus Role

      def level_ids_and_above
        level_ids_and_above_for(level_ids_in_grain)
      end

      # @param level_id [String] e.g. 'customers.last_name'
      # @param fact_record [Fact]
      def fetch_unsupported_level_value(level_id, fact_record)
        sought_level_definition = fact_record.sub_cube.definition_from_id(level_id)
        common_denominator_association = fact_record.sub_cube.common_denominator_level_association(level_id, prefer_query: true)
        with_level_scope(common_denominator_association.id) do |common_denominator_level_scope|
          common_denominator_level_scope.recursive_lookup_up fact_record.fact_key_for(common_denominator_association.id), level: sought_level_definition
        end
      end

      # @param level_id [String] e.g. 'customers.last_name'
      # @param fact_key_value [Integer] the primary key stored in the fact
      def fetch_supported_query_level_record(level_id, fact_key_value)
        with_level_scope(level_id) do |level_scope|
          raise Internal::Error.new('level must be query') unless level_scope.query?
          level_scope.recursive_lookup_up fact_key_value, level: level_scope
        end
      end

      def standardizer
        @standardizer ||= Martyr::MetricIdStandardizer.new(sub_cubes.first.cube_name, raise_if_not_ok: sub_cubes.length > 1)
      end

      private

      def map_reduce_sub_cubes
        if sub_cubes_hash.length == 1
          yield sub_cubes.first
        else
          arr = sub_cubes_hash.map do |sub_cube_name, sub_cube|
            [sub_cube_name, yield(sub_cube)]
          end
          Hash[arr]
        end
      end

      def metric_ids_lookup
        @metric_ids_lookup ||= metrics.index_by(&:id)
      end

    end
  end
end
