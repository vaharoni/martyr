module Martyr
  module Schema
    class BuiltInMetric < BaseMetric

      attr_accessor :statement, :fact_alias, :typecast, :sub_queries

      # A built in metric can be registered in a cube like so:
      # `has_sum_metric :published_book_count, "CASE WHEN books.published THEN 1 ELSE 0 END", subquery: :book_publications_sub`
      #
      # Built in metrics definitions accept a typecast option, that can be used the following ways:
      #   - As a String or Symbol. Martyr will interpret the fact value by calling the method given as the typecast option
      #     `has_sum_metric :published_book_count, "CASE WHEN books.published THEN 1 ELSE 0 END",
      #       subquery: :book_publications_sub, typecast: :to_i`
      #
      #   - As an Array. Martyr will interpret the fact value using the first element as the method, the rest as the arguments
      #   `has_max_metric :last_publication_time, "book_publications_sub.published_at", subquery: :book_publications_sub,
      #        typecast: [:to_time, :utc]`
      #
      #   - As a Proc
      #   `has_max_metric :last_publication_time, "book_publications_sub.published_at", subquery: :book_publications_sub,
      #        typecast: -> (time_string) { time_string.to_time(:utc) }`
      #
      #   - When no typecast option is given, the behaviour defaults to typecast: :to_i

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
        raw_fact_value = fact.raw.fetch(fact_alias.to_s)
        case typecast
        when NilClass
          raw_fact_value.to_i
        when Symbol, String, Array
          raw_fact_value.send(*Array.wrap(typecast))
        when Proc
          typecast.call(raw_fact_value)
        else
          error_message = "#{typecast.class.name} typecast option not supported. Give a Symbol, String, Array or Proc"
          raise RuntimeError.new(error_message)
        end
      rescue
        nil
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
