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

      def level_index
        @_level_index ||= collection.level_index(name)
      end
      alias_method :to_i, :level_index
    end
  end
end