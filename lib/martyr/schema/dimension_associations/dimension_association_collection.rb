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
        if has_key?(dimension_name)
          dimension_association = find_or_nil(dimension_name)
        else
          dimension = dimension_definitions.find_dimension(dimension_name)
          dimension_association = DimensionAssociation.new(dimension)
          register dimension_association
        end
        dimension_association.has_dimension_level(*args)
      end
    end
  end
end