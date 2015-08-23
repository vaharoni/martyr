module Martyr
  module Schema
    class BaseLevelDefinition
      include ActiveModel::Model
      include Martyr::Level

      attr_accessor :name
      delegate :dimension_name, to: :collection

      def supported?
        false
      end

      def level_above
        @_level_above ||= collection.level_above(name)
      end
    end
  end
end