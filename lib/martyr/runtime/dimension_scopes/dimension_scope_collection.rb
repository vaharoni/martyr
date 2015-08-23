module Martyr
  module Runtime
    class DimensionScopeCollection < HashWithIndifferentAccess
      include Martyr::Registrable

      attr_reader :dimension_definitions
      alias_method :find_dimension, :find_or_error

      def initialize(dimension_definitions)
        @dimension_definitions = dimension_definitions
      end

      # @param level [Martyr::Level]
      def register_level(level)
        if has_key?(level.dimension_name)
          level_scope_collection = find_or_nil(level.dimension_name)
        else
          dimension = dimension_definitions.find_dimension(level.dimension_name)
          level_scope_collection = Martyr::DimensionReference.new(dimension, Runtime::LevelScopeCollection)
          register level_scope_collection
        end
        level_scope_collection.register_level(level)
      end

      def find_level(dimension_name, level_name)
        find_or_error(dimension_name).find_level(level_name)
      end
    end
  end
end