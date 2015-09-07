module Martyr
  module Runtime
    class MetricMemorySlice
      attr_reader :metric
      delegate :to_hash, to: :slice_definition
      delegate :id, to: :metric, prefix: true

      # @param metric [BaseMetricDefinition]
      # @option data_slice [MetricDataSlice, nil] data slice from sub cube if exists
      def initialize(metric, data_slice = nil)
        @metric = metric
        @data_slice = data_slice
      end

      def set_slice(_metric_definition, **options)
        raise Martyr::Error.new('Internal error. Inconsistent metric received') unless _metric_definition.id == metric_id
        new_slice_definition = MetricSliceDefinition.new(metric: metric, **options)
        if @data_slice.blank?
          @slice_definition = new_slice_definition
        else
          @slice_definition = new_slice_definition.merge(data_slice)
        end
      end

      def get_slice(_metric_id)
        raise Martyr::Error.new('Internal error. Inconsistent metric received') unless _metric_id == metric_id
        @slice_definition
      end

    end
  end
end
