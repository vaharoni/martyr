module Martyr
  module Runtime
    class CompoundSlice

      attr_accessor :mart, :slices

      def initialize(mart)
        @mart = mart
        @slices = {}
      end

      def slice(*several_variants)
        if several_variants.length == 1 and several_variants.is_a?(Hash)
          compound_slice_hash = several_variants.first.stringify_keys.except('metrics')
          compound_slice_hash.each do |slice_on, *slice_definition|
            set_one_slice(slice_on, *slice_definition)
          end
        elsif several_variants.is_a? Array
          slice_on, *slice_definition = several_variants
          set_one_slice(slice_on, *slice_definition)
        else
          raise Query::Error.new("Invalid arguments for `where`: #{several_variants.inspect}")
        end
      end

      # @param scopeable [#apply_on_data]
      def apply_on_data(scopeable)
        slices.values.each {|slice| slice.apply_on_data(scopeable)}
      end

      def apply_in_memory(scopeable)
        slices.values.each {|slice| slice.apply_in_memory(scopeable)}
      end

      private

      def set_one_slice(slice_on, **slice_definition)
        slice = [:slice_degenerate_dimension, :slice_query_dimension, :slice_time_dimension, :slice_metric].map{|x| send(x, slice_on, **slice_definition)}.compact.first
        raise Query::Error.new("Could not find `#{slice_on}` to apply slice on") unless slice.present?
        @slices[slice_on] = slice
      end

      def slice_degenerate_dimension(slice_on, **slice_definition)
        dimension = mart.dimension_definitions[slice_on]
        return nil unless dimension.present? and dimension.is_a? Schema::DegenerateDimension
        DegenerateDimensionSlice.new dimension_definition: dimension, **slice_definition
      end

      def slice_query_dimension(slice_on, **slice_definition)
        dimension = mart.dimension_definitions[slice_on]
        return nil unless dimension.present? and (dimension.is_a? Schema::QueryDimension or dimension.is_a? Schema::SharedDimensionWrapper)
        QueryDimensionSlice.new dimension_definition: dimension, **slice_definition
      end

      def slice_time_dimension(slice_on, **slice_definition)
        dimension = mart.dimension_definitions[slice_on]
        return nil unless dimension.present? and dimension.is_a? Schema::TimeDimension
        TimeDimensionSlice.new dimension_definition: dimension, **slice_definition
      end

      def slice_metric(slice_on, **slice_definition)
        metric = mart.metric_definitions[slice_on]
        return nil unless metric.present?
        MetricSlice.new metric_definition: metric, **slice_definition
      end

    end
  end
end