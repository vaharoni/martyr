module Martyr
  module Schema
    class CountDistinctMetric < BuiltInMetric

      # @attribute level [Schema::BaseLevelDefinition]
      # @attribute null_unless [String] @see MetricDefinitionCollection#has_count_distinct_metric
      attr_accessor :level, :null_unless

      # @override
      def add_to_select(fact_scopes)
        fact_scopes.add_select_operator_for_metric(name) do |operator|
          operator.add_select(select_statement, as: inner_sql_helper_field, data_rollup_sql: data_rollup_sql)
        end
      end

      # @override
      def data_rollup_sql
        "COUNT(DISTINCT #{inner_sql_helper_field}) AS #{fact_alias}"
      end

      # @override
      # This is the trickiest part.
      # Consider count distinct on `customers.last_name`.
      #
      # The following scenarios exist:
      #   1. The level was not part of the fact to begin with.
      #     No rollup is possible unless the number of facts is exactly one.
      #     If we had a query on `media_types.name` and `genres.name`, and the element grain is exactly as the fact
      #     grain, we can display the metric as is. But if the element grain drops a level, it is impossible to rollup
      #     as we have to recalculate the distinct count.
      #
      #   2. The level was part of the fact and is also part of the element grain
      #     Can be retrieved from the first fact. All facts should have the same value.
      #
      #   3. The level was part of the fact but is not part of the element grain
      #     A DISTINCT count can be done in memory
      #
      def rollup(element)
        # Scenario 1
        unless element.facts.first.has_key?(level.id)
          if element.facts.length == 1
            return element.facts.first.fetch(id)
          else
            return "Invalid count distinct rollup. Add `#{level.id}` to the grain"
          end
        end

        # Scenario 2
        return element.facts.first.fetch(id) if element.grain_level_ids.include?(level.id)

        # Scenario 3
        element.facts.map{ |x| x.fact_key_for(level.id) }.uniq.length
      end

      private

      def select_statement
        return level.fact_key unless null_unless.present?
        "CASE WHEN #{null_unless} THEN #{level.fact_key} ELSE NULL END"
      end

      def inner_sql_helper_field
        return level.fact_alias unless null_unless.present?
        [fact_alias, 'distinct_helper'].join('_')
      end

    end
  end
end
