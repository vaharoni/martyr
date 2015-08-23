module Martyr
  module Schema
    class BaseFactDefinition
      attr_reader :cube, :scope, :dimension_associations
      alias_method :dimensions, :dimension_associations

      def supports_dimension_level?(dimension_name, level_name)
        dimension = dimension_associations[dimension_name]
        return false unless dimension

        lowest_supported_level_i = dimension.lowest_level.to_i
        considered_level_i = dimension_definitions.find_dimension(dimension_name).find_level(level_name).to_i
        considered_level_i <= lowest_supported_level_i
      end

      def has_dimension_level?(dimension_name, level_name)
        dimension = dimension_associations[dimension_name]
        dimension and dimension.has_level?(level_name)
      end
    end
  end
end
