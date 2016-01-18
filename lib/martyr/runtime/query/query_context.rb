module Martyr
  module Runtime
    class QueryContext
      include Martyr::LevelComparator
      include Martyr::Translations

      # @attribute metrics [Array<BaseMetric>] metrics that were requested as part of the query, without dependencies
      # @attribute sub_cubes_hash [Hash] of the format { cube_name => Runtime::SubCube }
      # @attribute dimension_scopes [Runtime::DimensionScopeCollection] see BaseCube::build_dimension_scopes
      # @attribute level_ids_in_grain [Array<String>] array of level IDs
      # @attribute virtual_cube [VirtualCube]
      # @attribute virtual_cube_metric_ids [Array<String>]

      attr_accessor :metrics, :sub_cubes_hash, :dimension_scopes, :level_ids_in_grain, :virtual_cube, :virtual_cube_metric_ids
      attr_reader :data_slice
      delegate :level_scope, :level_scopes, :with_level_scope, :lowest_level_of, :lowest_level_ids_of,
        :levels_and_above_for, :level_ids_and_above_for, :level_loaded?, to: :dimension_scopes
      delegate :slice, to: :memory_slice

      def initialize
        @data_slice = DataSlice.new(self)
        @sub_cubes_hash = {}
        @virtual_cube_metric_ids = []
      end

      def inspect
        "#<QueryContext metric_ids: #{metric_ids}, grain: #{level_ids_in_grain}, memory_slice: #{memory_slice.to_hash}, data_slice: #{data_slice.to_hash}, sub_cubes: #{sub_cubes}>"
      end

      def sub_cubes
        sub_cubes_hash.values
      end

      # @return [Array<BaseMetric>] if the current cube is virtual, returns array of metrics of the virtual cube
      def virtual_metrics
        return [] unless self.virtual_cube
        virtual_cube_metric_ids.map do |unique_metric_id|
          metric_id = second_element_from_id(unique_metric_id)
          virtual_cube.metric_definitions.find_or_error(metric_id)
        end
      end

      # @return [Array<String>] only metric IDs that were requested as part of the query, without dependencies
      def metric_ids
        metrics.map(&:id)
      end

      # @return [Array<BaseMetric>] all metrics, including those that are added by dependencies and virtuals
      def all_metrics
        sub_cubes.flat_map { |sub_cube| sub_cube.metric_objects } + virtual_metrics
      end

      def all_metric_ids
        all_metrics.map(&:id)
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
        dup_internals.slice!(*args)
      end

      # @return [QueryContext] for chaining
      def slice!(*args)
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
      #
      # @option sort [Array, Hash] either
      def elements(**options)
        load_bottom_level_primary_keys
        builder = VirtualElementsBuilder.new(memory_slice, unsliced_level_ids_in_grain: unsliced_level_ids_in_grain,
          virtual_metrics: virtual_metrics)

        sort_args = options.delete(:sort) || {}
        sorter = Sorter.new(standardizer.standardize(sort_args)) { |sort_argument| definition_from_id(sort_argument) }

        sub_cubes.each do |sub_cube|
          next unless sub_cube.metric_objects.present? or sub_cube.lowest_level_ids_in_grain.present?
          memory_slice_for_cube = memory_slice.for_cube(sub_cube)
          builder.add sub_cube.elements(memory_slice_for_cube, **options), sliced: memory_slice_for_cube.to_hash.present?
        end
        sorter.sort(builder.build)
      end

      def total(metrics: nil)
        elements(levels: [], metrics: metrics).first
      end
      alias_method :totals, :total

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
        sought_level_definition = dimension_scopes.find_level(level_id).level_definition
        common_denominator_association = fact_record.sub_cube.common_denominator_level_association(level_id, prefer_query: true)
        common_denominator_level_scope = level_scope(common_denominator_association.id)
        common_denominator_level_scope.recursive_lookup_up fact_record.fact_key_for(common_denominator_association.id), level: sought_level_definition
      end

      # @param level_id [String] e.g. 'customers.last_name'
      # @param fact_key_value [Integer] the primary key stored in the fact
      def fetch_supported_query_level_record(level_id, fact_key_value)
        level_scope = level_scope(level_id)
        raise Internal::Error.new('level must be query') unless level_scope.query?
        level_scope.recursive_lookup_up fact_key_value, level: level_scope
      end

      def standardizer
        @standardizer ||= Martyr::MetricIdStandardizer.new(default_cube.cube_name, raise_if_not_ok: virtual_cube?)
      end

      def dup_internals
        dup.instance_eval do
          @memory_slice = memory_slice.dup_internals
          self
        end
      end

      def element_helper_module
        return @element_helper_module if @element_helper_module
        @element_helper_module = Module.new
        dimension_scopes.register_element_helper_methods(@element_helper_module)

        all_metric_ids.each do |metric_id|
          metric_name = second_element_from_id(metric_id)
          @element_helper_module.module_eval do
            define_method(metric_name) { fetch(metric_id) }
          end
        end
        @element_helper_module
      end

      private

      def metric_ids_lookup
        @metric_ids_lookup ||= all_metrics.index_by(&:id)
      end

      def virtual_cube?
        sub_cubes.length > 1
      end

      def default_cube
        sub_cubes.first
      end

      def load_bottom_level_primary_keys
        return if @bottom_level_primary_keys_loaded
        sub_cubes.each do |sub_cube|
          sub_cube.lowest_level_ids_in_grain.each do |level_id|
            level = level_scope(level_id)
            next unless level.query?
            level.primary_keys_for_load ||= []
            level.primary_keys_for_load += sub_cube.facts.map{|x| x.raw[level.fact_alias]}
            level.primary_keys_for_load = level.primary_keys_for_load.uniq
          end
        end
        @bottom_level_primary_keys_loaded = true
      end

    end
  end
end
