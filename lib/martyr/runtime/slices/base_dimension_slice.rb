module Martyr
  module Runtime
    class BaseDimensionSlice
      include ActiveModel::Model

      validates_presence_of :dimension_definition
      attr_accessor :dimension_definition

      def dimension_name
        dimension_definition.try(:name)
      end
    end
  end
end