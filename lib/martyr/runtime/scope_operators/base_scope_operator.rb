module Martyr
  module Runtime
    class BaseScopeOperator
      attr_reader :block
      attr_accessor :fact_scope
      delegate :decorate_scope, to: :fact_scope

      def execute
        block.call(self)
      end
    end
  end
end
