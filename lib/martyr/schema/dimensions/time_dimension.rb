module Martyr
  module Schema
    class TimeDimension < DimensionDefinition

      # @param name [Symbol, String]
      # @param column [Symbol, String]
      def initialize(name, column: name)
        # TODO: convert the column into level definitions of week, month, and year
        super(name) do |dimension|
          dimension.add_level column, foreign_key: column
        end
      end

    end
  end
end