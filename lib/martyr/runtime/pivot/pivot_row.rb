module Martyr
  module Runtime
    class PivotRow
      include ActiveModel::Model

      attr_reader :pivot_table, :header, :cells
      delegate :column_axis, to: :pivot_table

      # @attribute header [Hash] array of keys and values for each grain in the axis
      def initialize(pivot_table, header, cells)
        @pivot_table = pivot_table
        @header = header
        @cells = cells
      end

      def inspect
        {row_header: header, column_headers: column_headers}.inspect
      end

      # = CSV

      def to_a(previous: nil)
        row_arr = header.values + cells_by_column_headers.values.map(&:value)
        return row_arr unless previous
        row_arr.each_with_index.map{|x, i| i < header.length && x.chomp(PivotCell::TOTAL_VALUE) == previous[i] ? nil : x}
      end

      # = Value retrieval

      def cell_at(column_header)
        cells_by_column_headers[column_header]
      end

      def [](index)
        cell_at column_headers[index]
      end

      def column_headers
        column_axis.hash_values_nil_hash.keys
      end

      def cells_by_column_headers
        @cells_by_column_headers ||= Hash[cells.map{|cell| [cell.to_axis_values(column_axis, flat: false), cell]}]
      end

    end
  end
end
