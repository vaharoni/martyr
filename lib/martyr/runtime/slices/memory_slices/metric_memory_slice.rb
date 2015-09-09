module Martyr
  module Runtime
    class MetricMemorySlice
      attr_reader :metric
      delegate :to_hash, to: :get_slice
      delegate :cube_name, to: :metric
      delegate :id, to: :metric, prefix: true

      # @param metric [BaseMetricDefinition]
      # @option data_slice [MetricDataSlice, nil] data slice from sub cube if exists
      def initialize(metric, data_slice = nil)
        @metric = metric
        @data_slice = data_slice
      end

      def keys
        [metric_id]
      end

      def set_slice(_metric_definition, **options)
        raise Martyr::Error.new('Internal error. Inconsistent metric received') unless _metric_definition.id == metric_id
        new_slice_definition = MetricSliceDefinition.new(metric: metric, **options)
        if @data_slice.blank?
          @slice_definition = new_slice_definition
        else
          @slice_definition = new_slice_definition.merge(data_slice)
        end
      end

      def get_slice(_metric_id)
        validate_consistency!(_metric_id) and @slice_definition
      end

      # = Applying

      def apply_on(facts)
        get_slice.combined_statements.inject(facts) do |selected_facts, or_statement_group|
          selected_facts.select do |fact|
            or_statement_group.inject(false) do |logic_resolve, statement|
              logic_resolve or fact.fetch(metric_id).send(statement[:memory_operator], statement[:value])
            end
          end
        end
      end

      private

      def validate_consistency!(metric_id)
        raise Martyr::Error.new('Internal error. Inconsistent metric received') unless metric_id == metric_id
        true
      end

    end
  end
end
