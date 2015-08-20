module Martyr
  module Schema
    class BaseLevelDefinition
      include ActiveModel::Model

      attr_accessor :collection, :name
      delegate :dimension_name, to: :collection

      def to_i
        collection.level_index(name)
      end

      def level_and_above
        collection.level_and_above(name)
      end

    end
  end
end