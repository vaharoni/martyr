module Martyr
  module Runtime
    class PivotAxis
      include ActiveModel::Model

      attr_accessor :grain_elements
      attr_reader :values

      def inspect
        grain_elements.inspect
      end

      def ids
        grain_elements.map(&:id)
      end

      # = CSV

      # Run on column axis only
      def add_header_column_cells_to_csv(csv, row_axis)
        grain_elements.each do |grain|
          prev_value = nil
          column_values = values.map do |x|
            # #chomp is just a trick to avoid removing consecutive (total)
            prev_value.try(:chomp, PivotCell::TOTAL_VALUE) == x[grain.id] ? nil : prev_value = x[grain.id]
          end
          csv << row_axis.csv_empty_row_axis_cells + column_values
        end
      end

      # Run on row axis only
      def csv_empty_row_axis_cells
        [nil] * grain_elements.length
      end

      # @return [Array<Hash>] where each hash is of format {level_id_1 => value_1, ... }
      def load_values(cells, reset: false)
        @values = nil if reset
        @values ||= cells.map { |cell| hash_grain_value_for(cell) }.uniq
      end

      def index_values_lookup
        @index_values_lookup ||= Hash[values.each_with_index.map{|value_hash, i| [value_hash, i]}]
      end

      def sort_cells_by_values(cells)
        cells.sort_by{|cell| index_values_lookup[hash_grain_value_for(cell)]}
      end

      def flat_values_nil_hash
        Hash[values.map{|hash| [hash.values.join(' : '), nil]}]
      end

      def hash_values_nil_hash
        Hash[values.map{|x| [x, nil]}]
      end

      def flat_grain_value_for(cell)
        grain_elements.map{ |grain| grain.cell_value(cell) }.join(' : ')
      end

      def hash_grain_value_for(cell)
        Hash[grain_elements.map{ |grain| [grain.id, grain.cell_value(cell)] }]
      end
    end
  end
end
