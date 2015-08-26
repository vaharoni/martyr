module Martyr
  module Schema
    class BuiltInMetric < BaseMetric

      attr_accessor :statement, :fact_alias

      def build_slice
        Runtime::MetricSlice.new(self)
      end

      def built_in?
        true
      end

      # @param fact_scopes [Runtime::FactScopeCollection]
      def add_to_select(fact_scopes)
        # We go directly through #supports_metric? and #decorate_scope because unsupported metrics should not result in
        # null cube scope.
        main_fact = fact_scopes.main_fact
        return unless main_fact.supports_metric?(name)

        main_fact.decorate_scope do |scope|
          scope.select("#{statement} AS #{fact_alias}")
        end
      end

      def extract(fact)
        fact.raw.fetch(fact_alias.to_s)
      end

    end
  end
end