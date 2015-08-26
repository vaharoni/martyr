module Martyr
  module Runtime
    class PivotAxis
      include ActiveModel::Model

      attr_accessor :grain_elements
      attr_reader :values

      # TODO: order elements

      # @return [Array<Hash>] where each hash is of format {level_id_1 => value_1, ... }
      def load_values(cells)
        @values ||= cells.map { |cell| hash_grain_value_for(cell) }.uniq!
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