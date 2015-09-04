module Martyr
  module Runtime
    class DimensionScopeCollection < HashWithIndifferentAccess
      include Martyr::Registrable
      include Martyr::Translations

      attr_accessor :sub_cube                         # must be initialized if dimension values are to get extracted from the fact
      attr_reader :dimension_definitions
      alias_method :find_dimension, :find_or_error
      alias_method :has_dimension?, :has_key?

      def initialize(dimension_definitions)
        @dimension_definitions = dimension_definitions
      end

      def to_s
        values.flat_map{|x| x.level_objects.map(&:id)}.inspect
      end

      # @param level [Martyr::Level]
      def register_level(level)
        dimension_scope = find_or_nil(level.dimension_name) ||
            register(Martyr::DimensionReference.new(level.dimension_definition, Runtime::LevelScopeCollection))
        dimension_scope.register_level(level)
      end

      def find_level(level_id)
        with_standard_id(level_id) { |dimension, level| find_dimension(dimension).find_level(level) }
      end
    end
  end
end