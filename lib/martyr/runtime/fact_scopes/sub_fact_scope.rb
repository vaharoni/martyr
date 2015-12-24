module Martyr
  module Runtime
    class SubFactScope < BaseFactScope

      delegate :add_to_join, to: :fact_definition

      def add_to_join(main_fact_scope)
        raise Schema::Error.new("Sub query #{name} does not have a join clause. Did you forget to call `joins_with`?") unless fact_definition.join_clause
        main_fact_scope.decorate_scope do |scope|
          scope.joins("#{fact_definition.join_clause} (#{scope_sql}) #{fact_definition.name} ON #{fact_definition.join_on}")
        end
      end

    end
  end
end
