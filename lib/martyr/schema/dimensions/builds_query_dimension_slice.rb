module Martyr
  module Schema
    module BuildsQueryDimensionSlice

      def build_slice(**slice_definition)
        Runtime::QueryDimensionSlice.new dimension_definition: self, **slice_definition
      end

    end
  end
end