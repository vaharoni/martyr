module Martyr
  module Runtime
    class PivotTableBuilder

      attr_reader :query_context, :on_columns_args, :on_rows_args, :in_cells_arg
      delegate :definition_from_id, to: :query_context

      delegate :cells, :elements, to: :table

      def initialize(query_context)
        @query_context = query_context
        @on_columns_args = []
        @on_rows_args = []
      end

      def select(*metric_ids)
        raise Query::Error.new('Invalid metric sent to `select`') unless metric_ids.all? { |x| definition_from_id(x).respond_to?(:metric?) }
        @metrics = metric_ids
        self
      end

      def on_columns(*level_ids)
        validate_metrics_in_level_ids(level_ids)
        @on_columns_args = level_ids.uniq
        self
      end

      def on_rows(*level_ids)
        validate_metrics_in_level_ids(level_ids)
        @on_rows_args = level_ids.uniq
        self
      end

      def in_cells(metric_id)
        raise Query::Error.new('Cannot have more than one metric in cells') if metric_id.to_s == 'metrics'
        raise Query::Error.new("#{metric_id} is not a valid metric name") unless Schema::BaseMetric.metric_id?(metric_id)
        @in_cells_arg = metric_id
        self
      end

      def build
        raise Query::Error.new('No columns were selected') unless on_columns_args.present?
        raise Query::Error.new('No rows were selected') unless on_rows_args.present?
        raise Query::Error.new('At least one metric has to be defined in pivot') unless metric_definition_count > 0
        raise Query::Error.new('Metrics can either be on columns or rows or in cells') if metric_definition_count > 1
        PivotTable.new sub_cube, metrics: metrics, pivot_grain: pivot_grain,
                       row_axis: axis_for(on_rows_args), column_axis: axis_for(on_columns_args)
      end
      alias_method :table, :build

      private

      def validate_metrics_in_level_ids(level_ids)
        level_ids.each do |level_id|
          raise Query::Error.new("#{level_id}: Cannot pivot on individual metrics. " +
                                     "Use 'metrics' for `on_columns` or `on_rows`, " +
                                     "`select` to restrict metrics or `in_cells` to display one metric") if Schema::BaseMetric.metric_id?(level_id) and level_id.to_s != 'metrics'
        end
      end

      def metric_ids
        return [in_cells_arg] if in_cells_arg
        @metrics || sub_cube.metric_ids
      end

      def metric_definition_count
        (in_cells_arg ? 1 : 0) + (on_columns_args + on_rows_args).select { |x| Schema::BaseMetric.metric_id?(x) }.length
      end

      def without_metrics(collection)
        collection.reject { |x| Schema::BaseMetric.metric_id?(x) }
      end

      def metrics
        metric_ids.map { |x| sub_cube.definition_from_id(x) }
      end

      def pivot_grain
        without_metrics(on_columns_args + on_rows_args)
      end

      def axis_for(collection)
        grain_elements = collection.map do |level_id|
          if level_id.to_s == 'metrics'
            Runtime::PivotGrainElement.new(id: level_id, metrics: metrics)
          else
            Runtime::PivotGrainElement.new(id: level_id, level_definition: sub_cube.definition_from_id(level_id))
          end
        end
        PivotAxis.new grain_elements: grain_elements
      end

    end
  end
end
