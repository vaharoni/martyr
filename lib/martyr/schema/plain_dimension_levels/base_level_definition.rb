module Martyr
  module Schema
    class BaseLevelDefinition
      include ActiveModel::Model
      include Martyr::Level

      attr_accessor :name
      delegate :dimension_name, :dimension_definition, to: :collection
      alias_method :slice_id, :dimension_name
      delegate :build_data_slice, :build_memory_slice, to: :dimension_definition

      # This allows to ask any Martyr::Level for #level_definition
      def level_definition
        self
      end

      def dimension_definition
        collection.dimension
      end

      def supported?
        false
      end
    end
  end
end
