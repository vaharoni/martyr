require 'martyr/schema/dimensions/dimension_definition'
module Martyr
  module Schema
    class DegenerateDimension < DimensionDefinition

      def initialize(name, levels: [])
        super(name) do |dimension|
          levels.each do |level|
            dimension.add_level level, foreign_key: level
          end
        end
      end

    end
  end
end