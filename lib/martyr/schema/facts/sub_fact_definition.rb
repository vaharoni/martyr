module Martyr
  module Schema
    class SubFactDefinition
      include ActiveModel::Model

      attr_accessor :name, :cube, :scope, :propagate_dimensions, :propagate_metrics

      # @return [Runtime::SubFactScope]
      def build
        Runtime::SubFactScope.new(self)
      end

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

    end
  end
end