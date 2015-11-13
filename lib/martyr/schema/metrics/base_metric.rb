module Martyr
  module Schema
    class BaseMetric
      include ActiveModel::Model
      extend Martyr::Translations

      attr_accessor :cube_name, :name, :rollup_function

      def id
        "#{cube_name}.#{name}"
      end

      alias_method :slice_id, :id

      # Used for reflection
      def metric?
        true
      end

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
              value += fact.fetch(id) || 0
            when 'min'
              value = [value, fact.fetch(id)].compact.min
            when 'max'
              value = [value, fact.fetch(id)].compact.max
            when 'none'
              # no-op
          end
        end
        value
      end
    end
  end
end
