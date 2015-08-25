module Martyr
  module Runtime
    class QueryMetrics < HashWithIndifferentAccess
      include Martyr::Registrable
      include Martyr::Translations

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

      def add_metric(metric_id)
        with_standard_id(metric_id) do |cube_name, metric_name|
          register cube.find_metric(metric_name) if cube_name == sub_cube.cube_name
        end
      end

      def add_all
        merge! cube.metrics
      end
    end
  end
end
