module Martyr
  module Runtime
    class MetricDependencyResolver
      include Martyr::Translations

      attr_reader :cube

      # @param cube [BaseCube] either virtual or regular cube
      def initialize(cube)
        @cube = cube
        @metrics_by_cube = {}
        @inferred_fact_grain_by_cube = {}
      end

      def to_hash
        Hash[@metrics_by_cube.map{ |cube_name, arr| [cube_name, arr.keys] }]
      end

      def inspect
        to_hash.inspect
      end

      # @option all [Boolean] send true if all metrics, including dependents, should be retrieved. Otherwise, only
      #   explicitly asked-for metrics will be included in the result set
      # @return [Array<BaseMetric>]
      def metrics(all: false)
        metric_entries = @metrics_by_cube.flat_map { |_cube_name, metric_ids_hash| metric_ids_hash.values }
        metric_entries.select! { |entry| entry[:explicit] } unless all
        metric_entries.map { |entry| entry[:metric] }
      end

      # @return [Array<String>] metric IDs
      def metric_ids(all: false)
        metrics(all: all).map(&:id)
      end

      # @param cube_name [String]
      # @option all [Boolean] send true if all metrics, including dependents, should be retrieved. Otherwise, only
      #   explicitly asked-for metrics will be included in the result set
      # @return [Array<BaseMetric>]
      def metrics_for(cube_name, all: false)
        relevant_entries_for(cube_name, all: all).map do |_metric_id, metric_entry|
          metric_entry[:metric]
        end
      end

      # @see metrics_for
      # @return [Array<String>] metric IDs
      def metric_ids_for(cube_name, all: false)
        relevant_entries_for(cube_name, all: all).map(&:first)
      end

      # @return [Array<String>] of all fact grains combined acrross cubes
      def inferred_fact_grain
        @inferred_fact_grain_by_cube.flat_map{ |_cube_name, levels_lookup_hash| levels_lookup_hash.keys }.uniq
      end

      # @return [Array<String>] array of level IDs that need to be part of the fact grain in order for the metrics to
      #   compute, including any dependent metrics. This does not include the default_fact_grain
      def inferred_fact_grain_for(cube_name)
        @inferred_fact_grain_by_cube[cube_name].try(:keys) || []
      end

      # Recursively add the metric and its dependencies
      # @param metric_id [String] fully qualified metric ID (with cube name)
      # @option explicit [Boolean] indicates whether the metric was asked to be included as part of a query.
      #   send false for metrics that were added due to dependency.
      def add_metric(metric_id, explicit: true)
        cube_name = first_element_from_id(metric_id)
        metric = cube.find_metric_id(metric_id)
        add_count_distinct_fact_grain_dependency(metric, explicit)
        return unless @metrics_by_cube[cube_name].try(:[], metric_id).nil?

        register_metric(metric, explicit)
        add_fact_grain_dependency(metric)
        add_dependent_metrics(metric)
      end

      def data_dup
        dup.instance_eval do
          @metrics_by_cube = @metrics_by_cube.deep_dup
          @inferred_fact_grain_by_cube = @inferred_fact_grain_by_cube.deep_dup
          self
        end
      end

      private

      def register_metric(metric, explicit)
        @metrics_by_cube[metric.cube_name] ||= {}
        @metrics_by_cube[metric.cube_name][metric.id] = { metric: metric, explicit: explicit }
      end

      # The level which count-distinct metric A depends on is added only if another metric depends on metric A,
      # and only if the user did not specify a custom fact_grain for metric A.
      def add_count_distinct_fact_grain_dependency(metric, explicit)
        return unless !explicit and metric.is_a?(Schema::CountDistinctMetric) and metric.fact_grain.blank?
        store_inferred_fact_grain(metric.cube_name, metric.level_id)
      end

      def add_fact_grain_dependency(metric)
        return unless metric.respond_to?(:fact_grain) and metric.fact_grain.present?
        metric.fact_grain.each do |level_id|
          store_inferred_fact_grain(metric.cube_name, level_id)
        end
      end

      # @param metric [BaseMetric]
      def add_dependent_metrics(metric)
        return unless metric.respond_to?(:depends_on) and metric.depends_on.present?
        metric.depends_on.each do |dependent_metric_id|
          add_metric(dependent_metric_id, explicit: false)
        end
      end

      # @see metrics_for
      def relevant_entries_for(cube_name, all:)
        candidates = @metrics_by_cube[cube_name] || []
        candidates.select!{ |_metric_id, metric_entry| metric_entry[:explicit] } unless all
        candidates
      end

      def store_inferred_fact_grain(cube_name, level_id)
        @inferred_fact_grain_by_cube[cube_name] ||= {}
        @inferred_fact_grain_by_cube[cube_name][level_id] = true
      end
    end
  end
end
