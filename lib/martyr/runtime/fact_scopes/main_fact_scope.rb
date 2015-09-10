module Martyr
  module Runtime
    class MainFactScope < BaseFactScope

      def add_scope_operator(operator)
        operator.fact_scope = self
        if operator.supported?
          operator.execute
        else
          # TODO: delete
          # set_null_scope
        end
      end
    end
  end
end
