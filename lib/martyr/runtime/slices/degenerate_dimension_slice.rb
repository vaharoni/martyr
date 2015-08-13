module Martyr
  module Runtime
    class DegenerateDimensionSlice < BaseDimensionSlice

      attr_accessor :with, :without

      validate do
        errors.add(:base, "Slice on `#{dimension_name}`: cannot have both `with` and `without`") if with and without
        errors.add(:base, "Slice on `#{dimension_name}`: must have either `with` and `without`") unless with or without
      end

      # @param scopeable [#update_scope]
      def apply_on_data(scopeable)
        if with.present?
          scopeable.update_scope(dimension_name: dimension_name) do |x|
            x.where(dimension_definition.fact_key => with)
          end
        elsif without.present?
          scopeable.update_scope(dimension_name: dimension_name) do |x|
            x.where.not(dimension_definition.fact_key => with)
          end
        end
      end

    end
  end
end