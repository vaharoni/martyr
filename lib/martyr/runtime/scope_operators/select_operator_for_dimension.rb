module Martyr
  module Runtime
    class SelectOperatorForDimension < BaseOperator

      attr_reader :what, :as

      def add_select(what, as:)
        @what = what
        @as = as
      end

      private

      def handle_inner(fact_scope)
        fact_scope.decorate_scope {|scope| scope.select("#{what} AS #{as}") }
      end

      def handle_outer(wrapper)
        wrapper.add_to_select(as)
      end

    end
  end
end
