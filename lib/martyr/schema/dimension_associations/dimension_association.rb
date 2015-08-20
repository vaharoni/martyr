module Martyr
  module Schema
    class DimensionAssociation
      include Martyr::Registrable
      include Martyr::Schema::HasLevelCollection

      attr_accessor :dimension_definition
      delegate :name, to: :dimension_definition
      delegate :has_dimension_level, to: :levels

      # @param dimension_definition [DimensionDefinition]
      def initialize(dimension_definition)
        @dimension_definition = dimension_definition
        @levels = LevelAssociationCollection.new(dimension: self)
      end

      def dimension_name
        dimension_definition.name
      end

      # @return [Runtime::PlainDimensionSlice]
      def build_slice
        Runtime::PlainDimensionSlice.new(self)
      end

    end
  end
end