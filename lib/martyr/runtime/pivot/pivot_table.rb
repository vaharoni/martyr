module Martyr
  module Runtime
    class PivotTable
      include ActiveModel::Model

      # @attribute metrics [Array<BaseMetric>]
      # @attribute row_axis [PivotAxis]
      # @attribute column_axis [PivotAxis]
      # @attribute pivot_grain [Array<String>] array of level ids
      attr_accessor :metrics, :row_axis, :column_axis, :pivot_grain, :row_totals, :column_totals, :sort
      attr_reader :elements

      def initialize(query_context, *args)
        super(*args)

        # We don't restrict metrics since custom rollups may have dependencies
        @elements = query_context.elements(levels: pivot_grain, sort: sort)
      end

      def reload
        @_cells = nil
        @_lowest_cells = nil
        row_axis.load_values(cells, reset: true)
        column_axis.load_values(cells, reset: true)
        self
      end

      def inspect
        {metrics: metrics.map(&:id), levels: pivot_grain, on_rows: row_axis, on_columns: column_axis, totals: {rows: row_totals, columns: column_totals}}.inspect
      end

      def cells
        @_cells ||= sort_cells(lowest_cells + sub_totals)
      end

      def lowest_cells
        @_lowest_cells ||= metrics.flat_map do |metric|
          elements.map do |element|
            PivotCell.new metric, element
          end
        end
      end

      def sub_totals
        resettable_grain = row_totals ? row_axis.ids : []
        resettable_grain += column_totals ? column_axis.ids : []
        resettable_grain -= [:metrics]
        (0...resettable_grain.length).flat_map do |x|
          reset = resettable_grain[x..-1]
          elements.index_by do |element|
            (pivot_grain - reset).map{|level_id| element[level_id]}
          end.flat_map do |_sub_total_key, representative|
            element = representative.locate reset: reset
            metrics.map do |metric|
              PivotCell.new(metric, element, reset)
            end
          end.reject(:empty?).compact
        end
      end

      def transpose
        self.row_axis, self.column_axis = column_axis, row_axis
        reload
      end

      def to_chart(name: nil)
        cells.group_by do |cell|
          cell.to_axis_values(row_axis)
        end.map do |row_grain_values, cells|
          data = cells.inject(column_axis.flat_values_nil_hash) { |h, cell| h.merge! cell.to_axis_values(column_axis) => cell.value }
          {name: name || row_grain_values, data: data}
        end
      end

      def to_csv
        CSV.generate do |csv|
          column_axis.add_header_column_cells_to_csv(csv, row_axis)
          prev_row = nil
          rows.each do |row|
            csv << prev_row = row.to_a(previous: prev_row)
          end
        end
      end

      def rows
        cells.group_by do |cell|
          cell.to_axis_values(row_axis, flat: false)
        end.map do |row_grain_values, cells|
          PivotRow.new(self, row_grain_values, cells)
        end
      end

      private

      def metrics_sort_order
        @_metrics_sort_order ||= Hash[metrics.each_with_index.map{|m, i| [m.id, i]}]
      end

      def sort_cells(cells_arr)
        return cells_arr if sort.present?
        cells_arr.sort_by do |cell|
          pivot_grain.map{|level_id| cell[level_id] || '' } + [metrics_sort_order[cell.metric_id]]
        end
      end

    end
  end
end

