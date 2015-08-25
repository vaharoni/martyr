module Martyr
  module Runtime
    class QueryMetrics < HashWithIndifferentAccess
      include Martyr::Registrable

      attr_reader :sub_cube

      delegate :cube, to: :sub_cube

      include Martyr::Delegators
      each_child_delegator :add_to_select, to: :values

      def initialize(sub_cube)
        @sub_cube = sub_cube
      end

      def inspect
        "#<#{self.class} #{keys}>"
      end

      def inspect_part
        "metrics: #{keys}"
      end

      def add_metric(metric_name)
        store metric_name, cube.find_metric(metric_name)
      end

      def set_all_if_empty
        merge! cube.metrics unless present?
      end
    end
  end
end
