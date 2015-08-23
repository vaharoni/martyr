module Martyr
  class Cube

    def self.fact_definitions
      @fact_definitions ||= Schema::FactDefinitionCollection.new(self)
    end

    # @return [Schema::Dimensions::DefinitionCollection]
    def self.dimension_definitions
      @dimension_definitions ||= Schema::DimensionDefinitionCollection.new(parent_schema_class)
    end

    def self.new_query_context
      Runtime::QueryContext.new(self)
    end

    class << self
      delegate :define_dimension, to: :dimension_definitions
      delegate :main_fact, :build_fact_scopes, to: :fact_definitions
      delegate :has_dimension_level, :has_count_metric, :has_min_metric, :has_max_metric,          # DSL
               :has_sum_metric, :has_custom_metric, :main_query,                                   # DSL
               :metrics, :dimensions, :rollups, :find_metric, :find_dimension, to: :main_fact      # Runtime

      delegate :select, :slice, :granulate, :pivot, to: :new_query_context
    end

    def self.martyr_schema_class?
      true
    end

    # @return [nil, Base]
    def self.parent_schema_class
      ancestors[1..-1].find{|x| x != self and x.respond_to?(:martyr_schema_class?)}
    end

    private_class_method :parent_schema_class

    # @return [Runtime::DimensionScopeCollection]
    #   If the level is defined in the cube but not supported by the main fact, the BaseLevelDefinition object will be
    #   wrapped with BaseLevelScope. If the level is supported, the LevelAssociation will be wrapped.
    def self.build_dimension_scopes
      dimension_scopes = Runtime::DimensionScopeCollection.new(dimension_definitions)
      dimension_definitions.all.each do |dimension_name, dimension_definition|
        dimension_definition.levels.each do |level_name, level_definition|
          level_association = dimensions[dimension_name].try(:levels).try(:[], level_name)
          dimension_scopes.register_level(level_association || level_definition)
        end
      end
      dimension_scopes
    end
  end
end