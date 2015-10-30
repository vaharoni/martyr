module Martyr
  class DimensionReference
    attr_reader :dimension_definition
    delegate :name, to: :dimension_definition

    include Martyr::HasLevelCollection

    # For reflection
    def dimension?
      true
    end

    def initialize(dimension_definition, levels_collection_class, &block)
      @dimension_definition = dimension_definition
      @levels = levels_collection_class.new(dimension: self, &block)
    end

    # Delegate everything to the concrete levels
    def method_missing(name, *args, &block)
      levels.respond_to?(name) ? levels.send(name, *args, &block) : super
    end
  end
end
