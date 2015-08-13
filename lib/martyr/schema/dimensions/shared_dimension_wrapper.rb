module Martyr
  module Schema
    # We use duck-typing instead of inheritence here. The interface methods will come from method_missing
    class SharedDimensionWrapper
      include Martyr::Schema::AppliesOnDataWithGroup
      include Martyr::Schema::BuildsQueryDimensionSlice

      attr_reader :dimension, :fact_key, :fact_alias

      # @param dimension [DimensionDefinition] the dimension in the parent scope
      def initialize(dimension, fact_key = nil, fact_alias: nil)
        @dimension = dimension
        @fact_key = fact_key || dimension.fact_key
        @fact_alias = fact_alias || dimension.fact_alias
      end

      def method_missing(name, *args)
        return dimension.send(name, *args) if dimension.respond_to?(name)
        super
      end

    end
  end
end