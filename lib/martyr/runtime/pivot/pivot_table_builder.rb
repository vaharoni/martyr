module Martyr
  module Runtime
    class PivotTableBuilder
      ALL_METRICS_KEY = 'metrics'

      attr_reader :query_context, :on_columns_args, :on_rows_args, :in_cells_arg, :row_totals, :column_totals
      delegate :standardizer, :definition_from_id, to: :query_context

      delegate :cells, :elements, :to_chart, to: :table

      def initialize(query_context)
        @query_context = query_context
        @on_columns_args = []
        @on_rows_args = []
        @row_totals = true
        @column_totals = true
      end

      def select(*metric_ids)
        @metrics = standardizer.standardize(metric_ids)
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

      def with_totals(rows: true, columns: true)
        @row_totals = !!rows
        @column_totals = !!columns
        self
      end

      def in_cells(metric_id)
        raise Query::Error.new('Cannot have more than one metric in cells') if metric_id.to_s == ALL_METRICS_KEY
        raise Query::Error.new("#{metric_id} is not a metric") unless metric?(metric_id)
        @in_cells_arg = standardizer.standardize(metric_id)
        self
      end

      def build
        raise Query::Error.new('No columns were selected') unless on_columns_args.present?
        raise Query::Error.new('No rows were selected') unless on_rows_args.present?
        raise Query::Error.new('At least one metric has to be defined in pivot') unless metric_definition_count > 0
        raise Query::Error.new('Metrics can either be on columns or rows or in cells') if metric_definition_count > 1
        PivotTable.new query_context, metrics: metrics, pivot_grain: pivot_grain,
                       row_axis: axis_for(on_rows_args), column_axis: axis_for(on_columns_args),
                       row_totals: row_totals, column_totals: column_totals
      end
      alias_method :table, :build

      private

      def metric?(id)
        return true if id == ALL_METRICS_KEY
        query_context.metric? standardizer.standardize(id)
      end

      def validate_metrics_in_level_ids(level_ids)
        level_ids.each do |level_id|
          next if level_id == ALL_METRICS_KEY
          level_id = standardizer.standardize(level_id)
          raise Query::Error.new("#{level_id}: Cannot pivot on individual metrics. " +
                                     "Use 'metrics' for `on_columns` or `on_rows`, " +
                                     "`select` to restrict metrics or `in_cells` to display one metric") if metric?(level_id)
        end
      end

      def metric_ids
        return [in_cells_arg] if in_cells_arg
        @metrics || query_context.metric_ids
      end

      def metric_definition_count
        (in_cells_arg ? 1 : 0) + (on_columns_args + on_rows_args).select { |x| metric?(x) }.length
      end

      def without_metrics(collection)
        collection.reject { |x| metric?(x) }
      end

      def metrics
        metric_ids.map { |x| query_context.metric(x) }
      end

      def pivot_grain
        without_metrics(on_columns_args + on_rows_args)
      end

      def axis_for(collection)
        grain_elements = collection.map do |level_id|
          if level_id.to_s == ALL_METRICS_KEY
            Runtime::PivotGrainElement.new(id: level_id, metrics: metrics)
          else
            Runtime::PivotGrainElement.new(id: level_id, level_definition: query_context.definition_from_id(level_id))
          end
        end
        PivotAxis.new grain_elements: grain_elements
      end

    end
  end
end
