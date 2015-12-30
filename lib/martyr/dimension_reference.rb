module Martyr
  class DimensionReference
    attr_reader :dimension_definition
    delegate :name, to: :dimension_definition

    include Martyr::HasLevelCollection

    delegate :lowest_level, :level_above, :find_level, :level_names, :level_objects, :has_level?,
      :has_dimension_level, :register_level, to: :levels

    # For reflection
    def dimension?
      true
    end

    def initialize(dimension_definition, levels_collection_class, &block)
      @dimension_definition = dimension_definition
      @levels = levels_collection_class.new(dimension: self, &block)
    end

    # @param mod [Module]
    def register_element_helper_methods(mod)
      level_objects.each {|l| l.register_element_helper_methods(mod)}
    end
  end
end
