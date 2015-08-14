module Martyr
  module Runtime
    class QueryDimensionSlice < BaseDimensionSlice

      attr_accessor :with, :without

      validate do
        errors.add(:base, "Slice on `#{dimension_name}`: cannot have both `with` and `without`") if with and without
        errors.add(:base, "Slice on `#{dimension_name}`: must have either `with` and `without`") unless with or without
      end

      # @param scopeable [#update_scope]
      def apply_on_data(scopeable)
        if with.present?
          scopeable.update_scope(dimension_name: dimension_name) do |fact_scope|
            fact_scope.scope.where(fact_scope.dimension_key_for_where(dimension_definition) => with)
          end
        elsif without.present?
          scopeable.update_scope(dimension_name: dimension_name) do |fact_scope|
            fact_scope.scope.where.not(fact_scope.dimension_key_for_where(dimension_definition) => with)
          end
        end
      end

    end
  end
end