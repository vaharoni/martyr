module Martyr
  module Runtime
    class MainFactScope < BaseFactScope

      # @param level [LevelAssociation]
      # @return [String] how to add a where condition to the level
      def level_key_for_where(level)
        level.fact_key
      end

      private

      # = Scope support check

      def if_supports_metric(name)
        if supports_metric?(name)
          yield if block_given?
          true
        else
          @scope = NullScope.new
          false
        end
      end

      def if_supports_dimension_level(dimension_name, level_name)
        if supports_dimension_level?(dimension_name, level_name)
          yield if block_given?
          true
        else
          @scope = NullScope.new
          false
        end
      end

    end
  end
end
