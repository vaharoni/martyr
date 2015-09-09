module Martyr
  module Runtime
    class PivotGrainElement
      include ActiveModel::Model

      attr_accessor :id, :metrics, :level_definition

      def inspect
        id.inspect
      end

      def cell_value(cell)
        if metrics.present?
          cell.metric_human_name
        else
          cell[level_definition.id]
        end
      end

    end
  end
end
