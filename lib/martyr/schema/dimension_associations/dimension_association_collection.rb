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
      def has_dimension_level(dimension_name, level_name, **args)
        if has_key?(dimension_name)
          dimension = find_or_nil(dimension_name)
        else
          dimension = dimension_definitions.find_dimension(dimension_name)
          dimension = Martyr::DimensionReference.new(dimension, LevelAssociationCollection)
          register dimension
        end
        dimension.has_dimension_level(level_name, **args)
      end

      def find_level(dimension_name, level_name)
        find_or_error(dimension_name).find_level(level_name)
      end
    end
  end
end