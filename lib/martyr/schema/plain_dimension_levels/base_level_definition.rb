module Martyr
  module Schema
    class BaseLevelDefinition
      include ActiveModel::Model

      attr_accessor :collection, :name
      delegate :dimension_name, to: :collection

      def to_i
        @_to_i ||= collection.level_index(name)
      end

      def level_and_above_full
        @_level_and_above_full ||= collection.level_and_above_full(name)
      end

      def level_and_below_full
        @_level_and_below_full ||= collection.level_and_below_full(name)
      end

      def level_above
        @_level_above ||= collection.level_above(name)
      end

    end
  end
end