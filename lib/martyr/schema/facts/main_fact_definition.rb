module Martyr
  module Schema
    class MainFactDefinition < BaseFactDefinition

      delegate :supports_dimension?, to: :dimension_definitions
      delegate :supports_metric?, to: :metric_definitions

      def name
        'main'
      end

      def dimension_key_for_where(dimension)
        dimension.fact_key
      end

    end
  end
end