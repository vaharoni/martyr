module Martyr
  class BaseCube

    def self.contained_cube_classes
      raise NotImplementedError
    end

    def self.new_query_context_builder
      Runtime::QueryContextBuilder.new(self)
    end

    def self.dimension_definitions
      {}
    end

    def self.supported_dimension_definitions
      raise NotImplementedError
    end

    # @param dimension_names
    # @return [Runtime::DimensionScopeCollection] a collection with dimensions that maintain SQL scoped queries and
    #   their results. All dimensions that have at least one level supported by the cube are included.
    def self.build_dimension_scopes(dimension_names)
      dimension_scopes = Runtime::DimensionScopeCollection.new(dimension_definitions)
      supported_dimension_definitions.slice(*dimension_names).values.flat_map(&:level_objects).each do |level|
        dimension_scopes.register_level(level)
      end
      dimension_scopes
    end


  end
end
