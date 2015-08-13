module Martyr
  module Schema
    class BuiltInMetric < BaseMetric

      attr_accessor :statement, :fact_alias

      def build_slice(**slice_definition)
        Runtime::MetricSlice.new metric_definition: self, **slice_definition
      end

      # @param scopeable [#update_scope]
      def apply_on_data(scopeable)
        scopeable.update_scope(metric_name: name) do |x|
          x.select("#{statement} AS #{fact_alias}")
        end
      end

    end
  end
end