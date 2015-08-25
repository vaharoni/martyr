module Martyr
  module Schema
    class BaseLevelDefinition
      include ActiveModel::Model
      include Martyr::Level

      attr_accessor :name
      delegate :dimension_name, :dimension_definition, to: :collection

      def dimension_definition
        collection.dimension
      end

      def supported?
        false
      end
    end
  end
end