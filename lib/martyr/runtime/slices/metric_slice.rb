module Martyr
  module Runtime
    class MetricSlice
      include ActiveModel::Model

      attr_reader :metric, :gt, :lt, :gte, :lte, :eq, :not
      delegate :statement, to: :metric
      delegate :name, to: :metric, prefix: true

      def initialize(metric)
        @metric = metric
      end

      def inspect_part
        operator_inspection = [gt_operator, gte || gt, lt_operator, lte || lt, eq ? '=' : nil, eq, self.not ? '!=' : nil, self.not].compact.join(' ')
        "metric: '#{metric_name}' #{operator_inspection}"
      end

      # This allows a `between` operation with two consecutive `slice`:
      #   cube.slice(:units_sold, '>1000').slice(:units_sold, '<5000')
      def set_slice(**options)
        @gt = options[:gt]
        @lt = options[:lt]
        @gte = options[:gte]
        @lte = options[:lte]
        @eq = options[:eq]
        @not = options[:not]
      end

      validate do
        errors.add(:base, "Slice on `#{metric_name}`: cannot have both `eq` and `not`") if eq and self.not
        errors.add(:base, "Slice on `#{metric_name}`: cannot have both `gt` and `gte`") if gt and gte
        errors.add(:base, "Slice on `#{metric_name}`: cannot have both `lt` and `lte`") if lt and lte
        errors.add(:base, "Slice on `#{metric_name}`: must have at least `lt`, `lte`, `gt`, `gte`, `eq`, or `not`") unless
            lt or lte or gt or gte or eq or self.not
      end

      def add_to_grain(grain)
        # no-op
      end

      # @param fact_scopes [Runtime::FactScopeCollection]
      def add_to_where(fact_scopes)
        add_scope_operator(fact_scopes, gt_operator, gte || gt) if gt_operator
        add_scope_operator(fact_scopes, lt_operator, lte || lt) if lt_operator
        add_scope_operator(fact_scopes, '=', eq) if eq
        add_scope_operator(fact_scopes, '!=', self.not) if self.not
      end

      private

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

      def add_scope_operator(fact_scopes, statement_operator, value)
        scope_operator = FactScopeOperatorForMetric.new(metric_name) do |operator|
          operator.decorate_scope do |scope|
            scope.having("#{statement} #{statement_operator} ?", value)
          end
        end
        fact_scopes.add_scope_operator(scope_operator)
      end

    end
  end
end