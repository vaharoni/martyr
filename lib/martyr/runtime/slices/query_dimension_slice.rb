module Martyr
  module Runtime
    class QueryDimensionSlice < BaseDimensionSlice

      attr_accessor :level, :with, :without
      delegate :level, to: :dimension_definition

      def apply_on_data(data_slice_builder)
        if with.present?
          data_slice_builder.update_scope(dimension_name: dimension_name) do |x|
            x.where(dimension_definition.foreign_key => with)
          end
        elsif without.present?
          data_slice_builder.update_scope(dimension_name: dimension_name) do |x|
            x.where.not(dimension_definition.foreign_key => with)
          end
        end
      end

    end
  end
end