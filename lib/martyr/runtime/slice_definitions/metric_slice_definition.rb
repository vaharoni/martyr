module Martyr
  class MetricSliceDefinition < BaseSliceDefinition

    OPERATORS = [:gt, :lt, :gte, :lte, :eq, :not]
    attr_accessor *OPERATORS

    def to_hash
      OPERATORS.inject({}) { |h, op| send(op) ? h.merge!(op => send(op)) : h }
    end

    def merge(other)
      if eq != other.eq
        merged = self.class.new
        merged.set_null and return merged
      end

      self.class.new gt: [other.gt, gt].compact.max,
                     gte: [other.gte, gte].compact.max,
                     lt: [other.lt, lt].compact.min,
                     lte: [other.lte, lte].compact.min,
                     eq: Array.wrap(other.eq) & Array.wrap(eq),
                     not: Array.wrap(other.not) + Array.wrap(self.not)
    end

    # @return [Array<Array<Hash>>]
    #   Every element in the top level array is an array with "OR" statements.
    #   The top level statements are to be combined with an "AND".
    #
    #   Example:
    #     [ [1,2,3], [4], [5] ]
    #     # => "(1 OR 2 OR 3) AND (4) AND (5)"
    #
    def combined_statements
      statements = []
      statements << [{operator: gt_operator, value: gt_value}] if gt_operator
      statements << [{operator: lt_operator, value: lt_value}] if lt_operator
      statements << Array.wrap(eq).map {|value| {operator: '=', value: value} } if eq

      Array.wrap(self.not).each do |value|
        statements << [{operator: '!=', value: value}]
      end

      statements
    end

    def gt_value
      gte || gt
    end

    def lt_value
      lte || lt
    end

    def gt_operator
      if gte.present?
        '>='
      elsif gt.present?
        '>'
      end
    end

    def lt_operator
      if lte.present?
        '<='
      elsif lt.present?
        '<'
      end
    end

    protected

    # TODO: fix for handling eq and not arrays
    def compile_operators
      enforce_eq and return
      enforce_range_overlap
    end

    def clear(except: nil, only: nil)
      if null? or (!except and !only)
        to_clear = OPERATORS
      elsif only
        to_clear = Array.wrap(only)
      elsif except
        to_clear = OPERATORS - Array.wrap(except).map(&:to_sym)
      end
      to_clear.each { |op| instance_variable_set("@#{op}", nil) }
      true
    end

    def enforce_eq
      return false unless eq.present?
      set_null if self.not == eq or (gte and gte > eq) or (gt and gt >= eq) or (lte and lte < eq) or (lt and lt <= eq)
      clear(except: :eq)
      true
    end

    def enforce_range_overlap
      lt <= lte ? clear(only: :lte) : clear(only: :lt) if lt and lte
      gt >= gte ? clear(only: :gte) : clear(only: :gt) if gt and gte
      set_null and clear and return if (lt || lte) and (gt || gte) and (lte == nil or lte != gte) and (lt || lte) <= (gt || gte)

      if lte == gte
        self.eq = lte
        enforce_eq
      end
    end

  end
end
