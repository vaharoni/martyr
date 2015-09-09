module Martyr
  module Runtime
    class QueryMetrics < HashWithIndifferentAccess
      include Martyr::Registrable
      include Martyr::Translations

      attr_reader :sub_cube

      delegate :cube, to: :sub_cube

      include Martyr::Delegators
      each_child_delegator :add_to_select, to: :values

      alias_method :find_metric, :find_or_error

      def initialize(sub_cube)
        @sub_cube = sub_cube
      end

      def inspect
        "#<#{self.class} #{to_a}>"
      end

      def to_a
        keys
      end

      def add_metric(metric_id)
        with_standard_id(metric_id) do |cube_name, metric_name|
          register cube.find_metric(metric_name) if cube_name == sub_cube.cube_name
        end
      end

      def add_all
        merge! cube.metrics
      end

      def built_in_metrics
        values.select{|x| x.is_a?(Schema::BuiltInMetric)}
      end

      def custom_metrics
        values.select{|x| x.is_a?(Schema::CustomMetric)}
      end

      def custom_rollups
        values.select{|x| x.is_a?(Schema::CustomRollup)}
      end

      def metric_ids
        values.map(&:id)
      end

      def metric_objects
        values
      end
    end
  end
end
