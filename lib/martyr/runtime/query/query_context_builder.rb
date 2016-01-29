module Martyr
  module Runtime
    # This is a SubCube builder. The builder method is #execute.
    # It takes the `select`, `slice`, and `granulate` clauses, makes sure they are well defined, and create a sub cube
    # as a result of their application.
    class QueryContextBuilder

      include Martyr::LevelComparator
      include Martyr::Translations

      attr_reader :cube, :scope_helper_module
      delegate :elements, :facts, :pivot, :total, :totals, to: :build

      def initialize(cube, scope_helper_module)
        @cube = cube
        @metric_dependency_resolver = MetricDependencyResolver.new(cube)
        @data_slice = {}
        @granulate_args = []
        @decorations = {}
        @scope_helper_module = scope_helper_module
        extend_scope_helper
      end

      # select(:a, :b, :c)
      # select(:all)
      def select!(*arr)
        @all_metrics = true and return self if arr.length == 1 and arr.first.to_s == 'all'
        standardize(arr).each do |metric_id|
          @metric_dependency_resolver.add_metric(metric_id)
        end
        self
      end

      # Variant 1 - full slice as one hash:
      #   slice('artist.name' => {with: 'AC/DC'}, 'genre.name' => {with: 'Rock'}, quantity: {gt: 0})
      #
      # Variant 2 - on one dimension or metric
      #   slice('artist.name', with: 'AC/DC')
      #
      def slice!(*several_variants)
        if several_variants.length == 1 and several_variants.first.is_a?(Hash)
          several_variants.first.stringify_keys.except(PivotCell::METRIC_COORD_KEY).each do |slice_on, slice_definition|
            @data_slice.merge! standardize(slice_on) => slice_definition
          end
        elsif several_variants.length == 2
          slice_on, slice_definition = several_variants
          @data_slice.merge! standardize(slice_on) => slice_definition
        else
          ArgumentError.new("wrong number of arguments (#{several_variants.length} for 1..2)")
        end
        self
      end

      # granulate('artist.name', 'genre.name')
      def granulate!(*arr)
        @granulate_args += arr
        self
      end

      # @param level_id [String]
      # @param *args [Array] will be sent to includes
      def decorate!(level_id, lambda = nil, &block)
        @decorations[level_id] = lambda || block
        self
      end

      def select(*args)
        data_dup.select!(*args)
      end

      def slice(*args)
        data_dup.slice!(*args)
      end

      def granulate(*args)
        data_dup.granulate!(*args)
      end

      def decorate(*args)
        data_dup.decorate!(*args)
      end

      def build
        return @context if @context
        context = QueryContext.new
        add_metric_slices_to_metric_dependencies
        add_all_metrics_if_none_selected
        setup_context_grain_and_metrics(context)
        setup_context_dimension_scopes(context)
        setup_context_sub_cubes_metrics_and_grain(context)
        setup_context_data_slice(context)
        setup_virtual_cube(context)
        decorate_all_scopes(context)
        @context = context
      end

      private

      # = Building steps

      def add_metric_slices_to_metric_dependencies
        @data_slice.keys.select{ |slice_on| cube.metric?(slice_on) }.each do |metric_id|
          @metric_dependency_resolver.add_metric(metric_id, explicit: false)
        end
      end

      def add_all_metrics_if_none_selected
        return unless @all_metrics
        return if @metric_dependency_resolver.metric_ids.present?
        cube.metrics.values.each do |metric|
          @metric_dependency_resolver.add_metric(metric.id)
        end
      end

      # Step 1
      # Add all levels to the query grain
      def setup_context_grain_and_metrics(context)
        context.level_ids_in_grain = Array.wrap(@granulate_args)
        context.metrics = @metric_dependency_resolver.metrics
      end

      # Step 2 (relies on Steps 1)
      # Build the dimension scope objects supported by the grain AND slices.
      #   DegeneratesAndBottomLevels.granulate('genres.name', 'media_types.name').slice('customers.country', with: 'USA')
      def setup_context_dimension_scopes(context)
        relevant_dimensions = (default_grains + context.level_ids_in_grain + @data_slice.keys).map { |x| first_element_from_id(x) }
        context.dimension_scopes = cube.build_dimension_scopes(relevant_dimensions.uniq)

        @decorations.each do |level_id, proc|
          context.dimension_scopes.find_level(level_id).decorate_scope(&proc)
        end
      end

      # Step 3
      # Setup the sub cubes, metrics, and grain for all cubes. Note that each cube only takes the levels of dimensions
      # it supports. That said, if dimension has levels L1, L2, L3 and a cube supports only L1 and L2, if L3 is
      # requested it will yield an empty cube.
      # If no metrics were given, select all.
      # If no grain was given, select all levels - separately for each cube.
      def setup_context_sub_cubes_metrics_and_grain(context)
        cube.contained_cube_classes.index_by(&:cube_name).each do |cube_name, cube_class|
          metric_ids = @metric_dependency_resolver.metric_ids_for(cube_name, all: true)
          grain = (@granulate_args + @metric_dependency_resolver.inferred_fact_grain_for(cube_name) +
                   cube_class.default_fact_grain).uniq

          sub_cube = Runtime::SubCube.new(context, cube_class)
          context.sub_cubes_hash[cube_name] = sub_cube
          sub_cube.set_metrics(metric_ids)
          sub_cube.set_grain(grain)
        end
      end

      # Step 4
      # Sets the data slice. Note that no slicing actually occurs - only setup.
      def setup_context_data_slice(context)
        @data_slice.each do |slice_on, slice_definition|
          context.data_slice.slice(slice_on, slice_definition)
        end
      end

      # Step 5
      # Sets the virtual cube
      def setup_virtual_cube(context)
        return unless cube.virtual?
        context.virtual_cube = cube
        context.virtual_cube_metric_ids = @metric_dependency_resolver.metric_ids_for(cube.cube_name, all: true)
      end

      # Step 6 (depends on steps 3 and 4)
      # All scopes are altered to represent the necessary queries - fact scopes (select, where, and group by) and
      # dimension scopes (where)
      def decorate_all_scopes(context)
        context.data_slice.add_to_dimension_scope(context)
        context.sub_cubes_hash.each do |_cube_name, sub_cube|
          sub_cube.decorate_all_scopes context.data_slice.for_cube(sub_cube)
        end
      end

      protected

      def extend_scope_helper
        return self unless scope_helper_module
        extend(scope_helper_module)
      end

      private

      def data_dup
        dup.instance_eval do
          @decorations = @decorations.try(:dup)
          @data_slice = @data_slice.dup
          @granulate_args = @granulate_args.dup
          @metric_dependency_resolver = @metric_dependency_resolver.data_dup
          extend_scope_helper
          self
        end
      end

      def standardize(object)
        @standardizer ||= Martyr::MetricIdStandardizer.new(cube.contained_cube_classes.first.cube_name,
          raise_if_not_ok: cube.contained_cube_classes.length > 1)

        @standardizer.standardize(object)
      end

      def default_grains
        (@metric_dependency_resolver.inferred_fact_grain +
          cube.contained_cube_classes.flat_map(&:default_fact_grain)).uniq
      end

    end
  end
end
