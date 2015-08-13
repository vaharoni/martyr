module Martyr
  module Schema
    class BuiltInMetric
      include ActiveModel::Model

      attr_accessor :name, :column, :aggregate_function, :rollup_function

    end
  end
end