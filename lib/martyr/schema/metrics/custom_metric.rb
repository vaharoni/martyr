module Martyr
  module Schema
    class CustomMetric
      include ActiveModel::Model

      attr_accessor :name, :block, :rollup_function

    end
  end
end