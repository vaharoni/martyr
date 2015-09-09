module Martyr
  module Runtime
    class PivotCell
      METRIC_COORD_KEY = 'metric'
      TOTAL_VALUE = '(total)'

      attr_reader :metric_id, :metric_human_name, :element
      delegate :facts, :coordinates, to: :element

      # @param sub_total_levels [Array<String>]
      def initialize(metric, element, sub_total_levels = [])
        @metric_id = metric.id
        @metric_human_name = metric.human_name
        @element = element
        @sub_total_levels = sub_total_levels
      end

      def inspect
        to_hash.inspect
      end

      def to_hash
        {'metric_human_name' => metric_human_name, 'value' => value}.merge!(element.grain_hash)
      end

      def coordinates
        element.coordinates.merge(METRIC_COORD_KEY => metric_id)
      end

      def to_axis_values(pivot_axis, flat: true)
        flat ? pivot_axis.flat_grain_value_for(self) : pivot_axis.hash_grain_value_for(self)
      end

      def value
        element.fetch(metric_id)
      end

      def [](key)
        case key.to_s
          when 'metric'
            metric_id
          when 'value'
            value
          else
            @sub_total_levels.include?(key.to_s) ? TOTAL_VALUE : element.fetch(key)
        end
      end
    end
  end
end
