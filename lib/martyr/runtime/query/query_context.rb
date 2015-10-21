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
        sub_cubes.flat_map { |sub_cube| sub_cube.metric_objects }
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
        raise Query::Error.new("Cannot slice on `#{slice_on}`: it is not in the grain") if slice_on_object.is_a?(Martyr::Level) and !supported_level_ids.include?(slice_on)
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

      # @return [Array<String>] array of level IDs that are in the memory slice
      def sliced_level_ids
        memory_slice.keys.reject{|id| metric?(id)}
      end

      # @return [Array<String>] array of level IDs that are in the grain but not sliced
      def unsliced_level_ids_in_grain
        level_ids_in_grain - sliced_level_ids
      end

      # = Run

      # @option cube_name [String, Symbol] default is first cube 
      # @return [Array<Fact>] of the chosen cube
      def facts(cube_name = nil)
        cube_name ||= default_cube.cube_name
        sub_cubes_hash[cube_name.to_s].facts
      end

      # A cube that has no grain and no metric doesn't matter - it will end up having one "useless" element with
      # no levels in the grain.
      # TODO: ignore cubes that do not share a grain or slice. Here is an algorithm:
      #   Start with a set of all metrics that are needed to be fetched.
      #   Add all cubes with metric-slices on them.
      #   If the shared grain is missing a level in the grain - add all cubes that support that level.
      #   If the shared grain is missing a level in ths slice - add all cubes that support that level.
      def elements(**options)
        builder = VirtualElementsBuilder.new unsliced_level_ids_in_grain: unsliced_level_ids_in_grain
        sub_cubes.each do |sub_cube|
          next unless sub_cube.metric_objects.present? or sub_cube.level_ids_in_grain.present?
          memory_slice_for_cube = memory_slice.for_cube(sub_cube)
          builder.add sub_cube.elements(memory_slice_for_cube, **options), sliced: memory_slice_for_cube.to_hash.present?
        end
        builder.build
      end

      def pivot
        Runtime::PivotTableBuilder.new(self)
      end

      # = Dispatcher

      # @return [BaseMetric, DimensionReference, BaseLevelDefinition]
      def definition_from_id(id)
        with_standard_id(id) do |x, y|
          return dimension_scopes[x].try(:dimension_definition) || default_cube.metrics[x] if !y
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
        @standardizer ||= Martyr::MetricIdStandardizer.new(default_cube.cube_name, raise_if_not_ok: virtual_cube?)
      end

      private

      def metric_ids_lookup
        @metric_ids_lookup ||= metrics.index_by(&:id)
      end

      def virtual_cube?
        sub_cubes.length > 1
      end

      def default_cube
        sub_cubes.first
      end

    end
  end
end
