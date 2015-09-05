module Martyr
  class Cube

    def self.contained_cube_classes
      [self]
    end

    def self.fact_definitions
      @fact_definitions ||= Schema::FactDefinitionCollection.new(self)
    end

    # @return [Schema::Dimensions::DefinitionCollection]
    def self.dimension_definitions
      @dimension_definitions ||= Schema::DimensionDefinitionCollection.new(parent_schema_class)
    end

    def self.new_query_context_builder
      Runtime::QueryContextBuilder.new(self)
    end

    def self.set_cube_name(value)
      @name = value.to_s
    end

    def self.cube_name
      @name || name.split('::').last.underscore
    end

    class << self
      delegate :define_dimension, to: :dimension_definitions
      delegate :main_fact, :build_fact_scopes, :sub_query, to: :fact_definitions
      delegate :has_dimension_level, :has_count_metric, :has_min_metric, :has_max_metric, # DSL
               :has_sum_metric, :has_custom_metric, :main_query, # DSL
               :metrics, :find_metric, :dimension_associations, :rollups, to: :main_fact # Runtime

      delegate :select, :slice, :granulate, :pivot, to: :new_query_context_builder
      alias_method :all, :new_query_context_builder
    end

    def self.martyr_schema_class?
      true
    end

    # @return [nil, Base]
    def self.parent_schema_class
      ancestors[1..-1].find { |x| x != self and x.respond_to?(:martyr_schema_class?) }
    end

    # @return [Hash] { dimension_name => PlainDimensionDefinition } including dimensions that have at least one level
    #   supported by the cube through #has_dimension_level
    def self.supported_dimension_definitions
      dimension_definitions.all.slice(*dimension_associations.keys)
    end

    def self.level_associations
      dimension_associations.flat_map { |_name, dimension_association| dimension_association.level_objects }
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