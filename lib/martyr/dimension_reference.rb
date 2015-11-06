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

    # TODO: manually delegate methods to improve performance
    # Delegate everything to the concrete levels
    # def method_missing(name, *args, &block)
    #   levels.respond_to?(name) ? levels.send(name, *args, &block) : super
    # end
  end
end
