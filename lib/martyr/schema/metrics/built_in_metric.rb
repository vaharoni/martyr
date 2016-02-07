module Martyr
  module Schema
    class BuiltInMetric < BaseMetric

      attr_accessor :statement, :fact_alias, :typecast, :sub_queries

      def build_data_slice(*args)
        Runtime::MetricDataSlice.new(self, *args)
      end

      def build_memory_slice(*args)
        Runtime::MetricMemorySlice.new(self, *args)
      end

      # @param fact_scopes [Runtime::FactScopeCollection]
      def add_to_select(fact_scopes)
        fact_scopes.add_select_operator_for_metric(name) do |operator|
          operator.add_select(statement, as: fact_alias, data_rollup_sql: data_rollup_sql)
        end
      end

      def extract(fact)
        fact.raw.fetch(fact_alias.to_s).try(:send, typecast || :to_i)
      end

      private

      def data_rollup_sql
        if rollup_function.to_s == 'none'
          fact_alias
        else
          "#{rollup_function.to_s.upcase}(#{fact_alias}) AS #{fact_alias}"
        end
      end

    end
  end
end
