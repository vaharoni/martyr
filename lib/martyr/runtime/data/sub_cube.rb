module Martyr
  module Runtime
    class SubCube

      attr_reader :cube, :fact_scopes, :dimension_scopes, :metrics, :grain, :compound_slice, :sliced
      delegate :combined_sql, :pretty_sql, :test, :select_keys, to: :fact_scopes
      delegate :has_dimension?, :find_dimension, :find_level, to: :dimension_scopes
      delegate :find_metric, to: :metrics

      # @param cube [Martyr::Cube]
      def initialize(cube)
        @cube = cube
        @fact_scopes = cube.build_fact_scopes
        @dimension_scopes = cube.build_dimension_scopes {|x| x.sub_cube = self}

        @metrics = QueryMetrics.new(self)
        @grain = QueryGrain.new(self)
        @compound_slice = CompoundSlice.new(self)
        @sliced = false
      end

      def inspect
        "#<#{self.class} cube: #{cube}, #{metrics.inspect_part}, #{compound_slice.inspect_part}, #{grain.inspect_part}>"
      end

      # = Definitions

      # @return [Dimension, BaseMetric, nil]
      def find_dimension_or_metric(name)
        dimension_scopes.find_or_nil(name) || metrics.find_or_nil(name)
      end

      # @param select_args [Array<Symbol, String>]
      def set_metrics(select_args)
        select_args.each do |metric_name|
          @metrics.add_metric(metric_name)
        end
      end

      def set_slice(slice_calls_args)
        slice_calls_args.each do |args|
          @compound_slice.slice(*args)
        end
      end

      def set_grain(granulate_calls_args)
        granulate_calls_args.each do |grain_hash|
          grain_hash.each do |dimension, level|
            @grain.add_granularity(dimension, level)
          end
        end
      end

      def set_defaults_and_dependencies
        metrics.set_all_if_empty
        compound_slice.add_to_grain(grain)
        grain.set_all_if_empty
        grain.nullify_scope_if_null(fact_scopes)
        dimension_scopes.keep_dimensions!(grain.supported_dimensions)
        dimension_scopes.remove_levels!(grain.levels_below_grain)
      end

      def slice_all_scopes
        grain.add_to_select(fact_scopes)
        metrics.add_to_select(fact_scopes)
        compound_slice.add_to_where(fact_scopes)
        grain.add_to_group_by(fact_scopes)
        @sliced = true
      end

      def foreign_keys_from_facts_for(level)
        facts.map { |x| x.send level.fact_alias }
      end

      # = Running

      def facts
        raise Query::Error.new('Sub cube must be sliced before facts can be retrieved') unless sliced
        @facts ||= fact_scopes.run.map { |x| Fact.new.merge! x.slice(*select_keys) }
      end

      def elements
        @elements ||= facts.map{|x| Element.new(self, x)}
      end

      def dimensions
        dimension_scopes.values
      end

      def dimension_ids
        dimensions.map(&:id)
      end

      def levels
        @levels ||= dimensions.flat_map(&:level_objects)
      end

      def level_ids
        levels.map(&:id)
      end

    end
  end
end
