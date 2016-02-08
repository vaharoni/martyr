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

            # Two scenarios:
            #   (1) The user does not specify a fact_grain on a rollup: :none custom metric
            #         The custom metric operates on the fact grain and is not rolled up when the element contains
            #         multiple facts. We return it only if the facts length is 1.
            #
            #   (2) fact_grain exists
            #         The custom metric operates on the levels provided by the user. There are three scenarios depending
            #         on the element grain:
            #         - Same level as the fact grain
            #             There is only one fact, and facts.first returns it
            #
            #         - More detailed level than the fact grain
            #             We should be able to pick any random fact.
            #
            #         - Less detailed than the fact grain
            #             If there is only one fact, we return its value, otherwise we avoid rolling up and return nil
            #
            element.facts.first.fetch(id) if element.facts.length == 1 or
              (fact_grain.present? and (fact_grain - element.grain_level_ids).empty?)
        end
      end
    end
  end
end
