module Martyr
  module Schema
    class SubFactDefinition < BaseFactDefinition

      attr_accessor :propagate_dimensions, :propagate_metrics

      # @param key [String, Symbol]
      # @return [Boolean]
      def supports_dimension?(key)
        propagate_dimensions.map(&:to_s).include? key.to_s
      end

      # @param key [String, Symbol]
      # @return [Boolean]
      def supports_metric?(key)
        propagate_metrics.map(&:to_s).include? key.to_s
      end

      def dimension_key_for_where(dimension)
        dimension.fact_alias
      end

    end
  end
end