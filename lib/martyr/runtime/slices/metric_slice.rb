module Martyr
  module Runtime
    class MetricSlice
      include ActiveModel::Model

      attr_accessor :metric_definition, :gt, :lt, :eq, :not

    end
  end
end