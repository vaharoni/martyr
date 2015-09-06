module Martyr
  module Schema
    class BaseMetric
      include ActiveModel::Model
      extend Martyr::Translations

      attr_accessor :cube_name, :name, :rollup_function

      # @return [Boolean] true for both generic 'metrics' and single metric ids such as 'metric.units_sold'
      def self.metric_id?(id)
        first_element_from_id(id) == 'metrics'
      end

      def unique_id
        "#{cube_name}.#{id}"
      end

      def id
        "metrics.#{name}"
      end

      alias_method :slice_id, :id

      def human_name
        name.to_s.titleize
      end

      def build_data_slice(*)
        raise NotImplementedError
      end

      def build_memory_slice(*)
        raise NotImplementedError
      end

      # @param fact_scopes [Runtime::FactScopeCollection]
      def add_to_select(fact_scopes)
        raise NotImplementedError
      end

      def extract(fact)
        raise NotImplementedError
      end

      # @param element [Runtime::Element]
      def rollup(element)
        value = 0
        element.facts.each do |fact|
          case rollup_function.to_s
            when 'count'
              value += 1
            when 'sum'
              value += fact.fetch(id)
            when 'min'
              value = [value, fact.fetch(id)].min
            when 'max'
              value = [value, fact.fetch(id)].max
          end
        end
        value
      end
    end
  end
end
