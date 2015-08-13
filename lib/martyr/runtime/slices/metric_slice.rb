module Martyr
  module Runtime
    class MetricSlice
      include ActiveModel::Model

      attr_accessor :metric_definition, :gt, :lt, :gte, :lte, :eq, :not
      delegate :statement, to: :metric_definition

      validate do
        errors.add(:base, "Slice on `#{metric_name}`: cannot have both `eq` and `not`") if eq and self.not
        errors.add(:base, "Slice on `#{metric_name}`: cannot have both `gt` and `gte`") if gt and gte
        errors.add(:base, "Slice on `#{metric_name}`: cannot have both `lt` and `lte`") if lt and lte
        errors.add(:base, "Slice on `#{metric_name}`: must have at least `lt`, `lte`, `gt`, `gte`, `eq`, or `not`") unless
            lt or lte or gt or gte or eq or self.not
      end

      def metric_name
        metric_definition.name
      end

      # @param scopeable [#update_scope]
      def apply_on_data(scopeable)
        apply_operator(scopeable, gt_operator, gte || gt) if gt_operator
        apply_operator(scopeable, lt_operator, lte || lt) if lt_operator
        apply_operator(scopeable, '=', eq) if eq
        apply_operator(scopeable, '!=', self.not) if self.not
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

      def apply_operator(scopeable, operator, value)
        scopeable.update_scope(metric_name: metric_name) do |x|
          x.having("#{statement} #{operator} ?", value)
        end
      end

    end
  end
end