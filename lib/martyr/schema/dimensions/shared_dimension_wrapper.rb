module Martyr
  module Schema
    # We use duck-typing instead of inheritence here. The interface methods will come from method_missing
    class SharedDimensionWrapper

      attr_reader :dimension
      attr_reader :selected_level

      # @param dimension [QueryDimension] the query dimension in the parent scope
      def initialize(dimension, use_level: nil)
        @dimension = dimension
        @selected_level = use_level ? dimension.levels.fetch(use_level) : dimension.selected_level
      end

      def method_missing(name, *args)
        return dimension.send(name, *args) if dimension.respond_to?(name)
        super
      end

    end
  end
end