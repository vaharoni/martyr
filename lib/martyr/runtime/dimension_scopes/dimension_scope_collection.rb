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
        "#<DimensionScopeCollection #{values.flat_map{|x| x.level_objects.map(&:id)}.inspect}>"
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

      # TODO: remove
      # def find_level(*several_variants)
      #   case several_variants.length
      #     when 1
      #       arg = several_variants.first
      #       if arg.is_a?(String)
      #         dimension_name, level_name = several_variants.first.split('.')
      #       elsif arg.respond_to?(:level_object?)
      #         dimension_name = arg.dimension_name
      #         level_name = arg.name
      #       else
      #         raise ArgumentError.new('Invalid argument')
      #       end
      #     when 2
      #       dimension_name, level_name = several_variants
      #     else
      #       raise ArgumentError.new("wrong number of arguments (#{several_variants.length} for 1..2)")
      #   end
      #   find_or_error(dimension_name).find_level(level_name)
      # end
    end
  end
end