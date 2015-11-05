module Martyr
  module Schema
    class BuiltInMetric < BaseMetric

      attr_accessor :statement, :fact_alias

      def build_data_slice(*args)
        Runtime::MetricDataSlice.new(self, *args)
      end

      def build_memory_slice(*args)
        Runtime::MetricMemorySlice.new(self, *args)
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
        fact.raw.fetch(fact_alias.to_s).try(:to_i)
      end

    end
  end
end
