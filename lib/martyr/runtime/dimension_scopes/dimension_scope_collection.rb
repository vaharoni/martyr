module Martyr
  module Runtime
    class DimensionScopeCollection < HashWithIndifferentAccess
      include Martyr::Registrable

      attr_accessor :sub_cube                         # must be initialized if dimension values are to get extracted from the fact
      attr_reader :dimension_definitions
      alias_method :find_dimension, :find_or_error
      alias_method :has_dimension?, :has_key?

      def initialize(dimension_definitions)
        @dimension_definitions = dimension_definitions
        yield self if block_given?
      end

      # @param level [Martyr::Level]
      def register_level(level)
        if has_key?(level.dimension_name)
          dimension_scope = find_or_nil(level.dimension_name)
        else
          dimension = dimension_definitions.find_dimension(level.dimension_name)
          dimension_scope = Martyr::DimensionReference.new(dimension, Runtime::LevelScopeCollection) {|x| x.sub_cube = sub_cube}
          register dimension_scope
        end
        dimension_scope.register_level(level)
      end

      # Removes all dimensions except for those that are provided
      def keep_dimensions!(dimension_names)
        (keys - dimension_names).each do |dimension_name|
          delete dimension_name
        end
      end

      # @param levels_below_grain_hash [Hash] { 'dimension_name' => ['level1', 'level2']  }
      def remove_levels!(levels_below_grain_hash)
        levels_below_grain_hash.each do |dimension_name, level_names_to_remove|
          find_dimension(dimension_name).remove_levels!(level_names_to_remove)
        end
      end

      def find_level(*several_variants)
        case several_variants.length
          when 1
            arg = several_variants.first
            if arg.is_a?(String)
              dimension_name, level_name = several_variants.first.split('.')
            elsif arg.respond_to?(:level_object?)
              dimension_name = arg.dimension_name
              level_name = arg.name
            else
              raise ArgumentError.new('Invalid argument')
            end
          when 2
            dimension_name, level_name = several_variants
          else
            raise ArgumentError.new("wrong number of arguments (#{several_variants.length} for 1..2)")
        end
        find_or_error(dimension_name).find_level(level_name)
      end
    end
  end
end