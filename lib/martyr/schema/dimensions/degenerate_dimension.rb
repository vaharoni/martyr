require 'martyr/schema/dimensions/dimension_definition'
module Martyr
  module Schema
    class DegenerateDimension < DimensionDefinition

      # @param name [Symbol, String]
      # @param fact_key [String]
      def initialize(name, fact_key = name, fact_alias: nil)
        super(name: name.to_s, fact_key: fact_key, fact_alias: normalize_alias(fact_alias || name))
      end

      def build_slice(**slice_definition)
        Runtime::DegenerateDimensionSlice.new dimension_definition: self, **slice_definition
      end

    end
  end
end