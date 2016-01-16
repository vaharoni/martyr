module Martyr
  module Schema
    class BaseMetric
      include ActiveModel::Model
      extend Martyr::Translations

      attr_accessor :cube_name, :name, :rollup_function, :sort, :fact_grain

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
        case rollup_function.to_s
          when 'count'
            element.facts.length
          when 'sum'
            element.facts.map{|x| x.fetch(id) || 0}.reduce(:+)
          when 'min'
            element.facts.map{|x| x.fetch(id)}.compact.min
          when 'max'
            element.facts.map{|x| x.fetch(id)}.compact.max
          when 'none'
            values = element.facts.map{|x| x.fetch(id)}
            return values.first if values.uniq.length == 1
        end
      end
    end
  end
end
