module Martyr
  module Schema
    class DimensionAssociationCollection < HashWithIndifferentAccess
      include Martyr::Registrable

      attr_reader :dimension_definitions
      alias_method :find_dimension, :find_or_error
      alias_method :supports_dimension?, :has_key?

      # @param dimension_definitions [DimensionDefinitionCollection]
      def initialize(dimension_definitions)
        @dimension_definitions = dimension_definitions
      end

      # @return [LevelAssociation]
      def has_dimension_level(dimension_name, *args)
        dimension = dimension_definitions.find_dimension(dimension_name)
        dimension_association = DimensionAssociation.new(dimension)
        level_association = dimension_association.has_dimension_level(*args)
        register dimension_association
        level_association
      end
    end
  end
end