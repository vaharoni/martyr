module Martyr
  module Runtime
    class SubFactScope < BaseFactScope

      delegate :add_to_join, to: :fact_definition

      # @param level [BaseLevelScope] note that LevelScope objects are always associated with the main fact
      # @return [String] how to add a where condition to the level
      def level_key_for_where(level)
        fact_definition.find_level(level.dimension_name, level.name).fact_key
      end

      def add_scope_operator(operator)
        operator.fact_scope = self
        operator.execute if operator.supported?
      end

      def add_to_join(main_fact_scope)
        raise Schema::Error.new("Sub query #{name} does not have a join clause. Did you forget to call `joins_with`?") unless fact_definition.join_clause
        main_fact_scope.decorate_scope do |scope|
          scope.joins("#{fact_definition.join_clause} (#{scope_sql}) #{fact_definition.name} ON #{fact_definition.join_on}")
        end
      end

    end
  end
end
