module Martyr
  module Runtime
    class SubFactScope < BaseFactScope

      # @param level [LevelAssociation]
      # @return [String] how to add a where condition to the level
      def level_key_for_where(level)
        level.fact_alias
      end

      private

      # = Scope support check

      def if_supports_metric(name)
        if supports_metric?(name)
          yield if block_given?
          true
        else
          false
        end
      end

      # Sub facts are required to propagate all levels of a dimension; so we rely on the MainFactScope to check for
      # level support and here only care about dimension_name
      def if_supports_dimension_level(dimension_name, _level_name)
        if supports_dimension?(dimension_name)
          yield if block_given?
          true
        else
          false
        end
      end

    end
  end
end
