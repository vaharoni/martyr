module Martyr
  # The conversion from and to interval sets is used for merging between data slices and memory slices.
  class MetricSliceDefinition < BaseSliceDefinition

    OPERATORS = [:gt, :lt, :gte, :lte, :eq, :not]
    attr_accessor *OPERATORS

    def self.from_interval_set(interval_set)
      new interval_set_to_hash(interval_set)
    end

    def to_hash
      OPERATORS.inject({}) { |h, op| send(op) ? h.merge!(op => send(op)) : h }
    end

    def merge(other)
      self.class.from_interval_set(to_interval_set.intersect(other.to_interval_set))
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

    protected

    def compile_operators
      hash = interval_set_to_hash(to_interval_set)
      OPERATORS.each do |operator|
        instance_variable_set "@#{operator}", hash[operator]
      end
      set_null if hash.compact.empty?
    end

    def self.interval_set_to_hash(interval_set)
      return {} if interval_set.null?
      not_arr = interval_set.extract_and_fill_holes.presence
      eq_arr = interval_set.extract_and_remove_points.presence
      raise Martyr::Error.new('Unexpected interval set format') unless interval_set.null? or interval_set.continuous?

      upper_point = interval_set.upper_bound
      lte = upper_point.x if upper_point.try(:closed?)
      lt = upper_point.x if upper_point.try(:open?)

      lower_point = interval_set.lower_bound
      gte = lower_point.x if lower_point.try(:closed?)
      gt = lower_point.x if lower_point.try(:open?)

      { not: not_arr, eq: eq_arr, lte: lte, lt: lt, gte: gte, gt: gt }
    end
    delegate :interval_set_to_hash, to: 'self.class'

    # Calculate each time to avoid messing up internal state
    def to_interval_set
      interval_set = IntervalSet.new.add
      merge_eq_interval_set(interval_set)
      merge_not_interval_set(interval_set)
      interval_set.intersect IntervalSet.new(to: lt) if lt
      interval_set.intersect IntervalSet.new(to: [lte]) if lte
      interval_set.intersect IntervalSet.new(from: gt) if gt
      interval_set.intersect IntervalSet.new(from: [gte]) if gte
      interval_set
    end

    def merge_eq_interval_set(interval_set)
      return unless eq.present?
      set = IntervalSet.new
      Array.wrap(eq).each {|x| set.add(from: [x], to: [x]) }
      interval_set.intersect(set)
    end

    def merge_not_interval_set(interval_set)
      return unless self.not.present?
      Array.wrap(self.not).
        map {|x| IntervalSet.new(to: x).add(from: x) }.
        inject(interval_set) {|set, hole| set.intersect(hole)}
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
  end
end
