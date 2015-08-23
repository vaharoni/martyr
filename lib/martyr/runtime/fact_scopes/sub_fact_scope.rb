module Martyr
  module Runtime
    class SubFactScope < BaseFactScope

      # @param level [LevelAssociation]
      # @return [String] how to add a where condition to the level
      def level_key_for_where(level)
        level.fact_alias
      end

      def add_scope_operator(operator)
        operator.fact_scope = self
        operator.execute if operator.supported?
      end

    end
  end
end
