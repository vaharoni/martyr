module Martyr
  module Runtime
    class MainFactScope < BaseFactScope

      # @param level [LevelAssociation]
      # @return [String] how to add a where condition to the level
      def level_key_for_where(level)
        level.fact_key
      end

      def add_scope_operator(operator)
        operator.fact_scope = self
        if operator.supported?
          operator.execute
        else
          set_null_scope
        end
      end
    end
  end
end
