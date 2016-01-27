module Martyr
  module Schema
    class CountDistinctMetric < BuiltInMetric

      # Allows predetermining and caching the rollup strategy that will be used to rollup metrics of elements. This has
      # performance benefits when rolling up a large array of elements that were the result of the same query.
      #
      # Usage:
      #
      #   CountDistinctMetric.enable_rollup_strategy_caching(metrics) do
      #     # Code use to rollup (compute) metrics of many elements
      #   end
      #
      # @param metrics [Array<BaseMetric>] any metric that is planned to be rolled up. The subset of count distinct
      #   metrics will be used.
      # @param element_grain [Array<String>] array of level IDs
      # @param fact_grain [Array<String>] array of level IDs
      def self.enable_rollup_strategy_caching(metrics)
        relevant_metrics = metrics.select {|metric| metric.is_a?(self)}

        relevant_metrics.each do |count_distinct_metric|
          count_distinct_metric.send(:enable_rollup_strategy_caching)
        end

        yield

      ensure
        relevant_metrics.each do |count_distinct_metric|
          count_distinct_metric.send(:cleanup_rollup_strategy)
        end
      end

      # @attribute level [Schema::BaseLevelDefinition]
      # @attribute null_unless [String] @see MetricDefinitionCollection#has_count_distinct_metric
      attr_accessor :level, :null_unless
      delegate :id, to: :level, prefix: true

      # @override
      def add_to_select(fact_scopes)
        # Adding an inner SQL statement with the metric's fact_alias is essential for metric slices
        # Note that it is not used for the rollup in the wrapper
        fact_scopes.add_select_operator_for_metric(name) do |operator|
          operator.add_select(inner_sql_statement, as: fact_alias)
        end

        fact_scopes.add_select_operator_for_metric(name) do |operator|
          operator.add_select(select_statement, as: inner_sql_helper_field, data_rollup_sql: data_rollup_sql)
        end
      end

      # @override
      def data_rollup_sql
        "COUNT(DISTINCT #{inner_sql_helper_field}) AS #{fact_alias}"
      end

      # @override
      def rollup(element)
        rollup_strategy(element).run(element)
      end

      private

      def inner_sql_statement
        return '1' unless null_unless.present?
        "CASE WHEN #{null_unless} THEN 1 ELSE 0 END"
      end

      def select_statement
        return level.fact_key unless null_unless.present?
        "CASE WHEN #{null_unless} THEN #{level.fact_key} ELSE NULL END"
      end

      def inner_sql_helper_field
        return level.fact_alias unless null_unless.present?
        [fact_alias, 'distinct_helper'].join('_')
      end

      # @return [RollupStrategy] cached version if caching is enabled, otherwise a newly minted object
      def rollup_strategy(element)
        return @rollup_strategy if @rollup_strategy_caching_enabled and @rollup_strategy
        rollup_strategy = RollupStrategy.new(self, element.grain_level_ids, element.facts.first.grain_level_ids)
        @rollup_strategy = rollup_strategy if @rollup_strategy_caching_enabled
        rollup_strategy
      end

      def enable_rollup_strategy_caching
        @rollup_strategy_caching_enabled = true
      end

      def cleanup_rollup_strategy
        @rollup_strategy = nil
        @rollup_strategy_caching_enabled = false
      end

      class RollupStrategy
        attr_reader :metric, :strategy_method

        # This is the trickiest part.
        # Consider count distinct on `customers.last_name`.
        #
        # The following scenarios exist:
        #   1. The level was not part of the fact to begin with.
        #     There are some cases in which double counting cannot be avoided, hence rollup is not always possible.
        #     For example, let's say we had a query on `media_types.name` and `genres.name`.
        #     For every given combination, the fact holds a distinct count of the number of customers.
        #     However, the same customer may have bought different combinations of media types and genres.
        #     Therefore, if we remove `genres.name` from the element grain we have no way to correctly rollup the number
        #     of distinct customers per media type.
        #
        #     There are two exceptions in which rollup is allowed:
        #     (a) No levels were dropped between fact grain and element grain.
        #     (b) Some levels were dropped, but all of them represent levels above `customers.last_name`.
        #
        #     If we had a query on `media_types.name` and `customers.country`, if we drop `customers.country` we can
        #     perform a SUM of the facts.
        #
        #   2. The level was part of the fact and is also part of the element grain
        #     Can be retrieved from the first fact. All facts should have the same value.
        #
        #   3. The level was part of the fact but is not part of the element grain
        #     A DISTINCT count can be done in memory
        #
        def initialize(metric, element_grain, fact_grain)
          @metric = metric

          # Scenario 1
          unless fact_grain.include?(metric.level_id)
            acceptable_removed_level_ids = metric.level.level_and_above.map(&:id)
            if (element_grain - fact_grain).all? { |level_id| acceptable_removed_level_ids.include?(level_id) }
              @strategy_method = :sum
            else
              @strategy_method = :error
            end
            return
          end

          # Scenario 2
          if element_grain.include?(metric.level_id)
            @strategy_method = :first
            return
          end

          # Scenario 3
          @strategy_method = :uniq
        end

        def run(element)
          send(strategy_method, element)
        end

        private

        def sum(element)
          element.facts.map{|fact| fact.fetch(metric.id)}.reduce(:+)
        end

        def error(_element)
          "Invalid count distinct rollup. Add `#{metric.level_id}` to the grain"
        end

        def first(element)
          element.facts.first.fetch(metric.id)
        end

        def uniq(element)
          # We check for fetch(metric.id) > 0 for the sake of the use of +null_unless+ option
          element.facts.select { |x| x.fetch(metric.id) > 0 }.map{ |x| x.fact_key_for(metric.level_id) }.uniq.length
        end
      end
    end
  end
end
