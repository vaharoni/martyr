module Martyr
  module Runtime
    class DimensionScopeCollection < HashWithIndifferentAccess
      include Martyr::Registrable
      include Martyr::Translations

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
      alias_method :level_scope, :find_level

      def level_scopes(level_ids)
        Array.wrap(level_ids).map{|x| level_scope(x)}
      end

      # @param level_id [String]
      # @yieldparam [BaseLevelScope]
      def with_level_scope(level_id)
        yield level_scope(level_id)
      end

      def level_loaded?(level_id)
        level_scope(level_id).loaded?
      end

      # @param level_ids [Array<String>, String]
      # @return [Array<BaseLevelScope>] lowest levels from the levels array in each dimension
      def lowest_level_of(level_ids)
        LevelDefinitionsByDimension.new(level_scopes(level_ids)).lowest_levels
      end

      # @param level_ids [Array<String>, String]
      # @return [String] lowest levels from the levels array in each dimension
      def lowest_level_ids_of(level_ids)
        lowest_level_of(level_ids).map(&:id)
      end

      # @param level_ids [Array<String>, String]
      # @return [Array<BaseLevelScope>] lowest levels from the levels array in each dimension, and all the level
      #   scopes above them
      def levels_and_above_for(level_ids)
        lowest_level_of(level_ids).flat_map(&:level_and_above)
      end

      # @param level_ids [Array<Martyr::Level>]
      # @return [Array<String>]
      def level_ids_and_above_for(level_ids)
        levels_and_above_for(level_ids).map(&:id)
      end

    end
  end
end
