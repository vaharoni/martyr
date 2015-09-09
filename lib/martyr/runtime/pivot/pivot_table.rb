module Martyr
  module Runtime
    class PivotTable
      include ActiveModel::Model

      # @attribute metrics [Array<BaseMetric>]
      # @attribute row_axis [PivotAxis]
      # @attribute column_axis [PivotAxis]
      # @attribute pivot_grain [Array<String>] array of level ids
      attr_accessor :metrics, :row_axis, :column_axis, :pivot_grain
      attr_reader :elements

      def initialize(query_context, *args)
        super(*args)
        @elements = query_context.elements(levels: pivot_grain, metrics: metrics)
        row_axis.load_values(cells)
        column_axis.load_values(cells)
      end

      def cells
        @_cells ||= metrics.flat_map do |metric|
          elements.map do |element|
            PivotCell.new metric, element
          end
        end
      end

      def transpose
        self.row_axis, self.column_axis = column_axis, row_axis
      end

      def to_chart
        cells.group_by do |cell|
          cell.to_axis_values(row_axis)
        end.map do |row_grain_values, cells|
          data = cells.inject(column_axis.flat_values_nil_hash) { |h, cell| h.merge! cell.to_axis_values(column_axis) => cell.value }
          {name: row_grain_values, data: data}
        end
      end

      def rows
        cells.group_by do |cell|
          cell.to_axis_values(row_axis, flat: false)
        end.map do |row_grain_values, cells|
          PivotRow.new(self, row_grain_values, cells)
        end
      end

    end
  end
end

