module Martyr
  module Schema
    class TimeDimension

      # @param name [Symbol, String]
      # @param column [Symbol, String]
      def initialize(name, column: name)
        # TODO: convert the column into level definitions of week, month, and year
        # super(name: name.to_s) do |dimension|
        #   dimension.add_level column, foreign_key: column
        # end
      end

      def build_slice(**slice_definition)
        Runtime::TimeDimensionSlice.new dimension_definition: self, **slice_definition
      end

      def find_level(name)
        # TODO: implement
      end

    end
  end
end