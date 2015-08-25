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

    class << self
      delegate :define_dimension, to: :dimension_definitions
      delegate :main_fact, :build_fact_scopes, :sub_query, to: :fact_definitions
      delegate :has_dimension_level, :has_count_metric, :has_min_metric, :has_max_metric, # DSL
               :has_sum_metric, :has_custom_metric, :main_query, # DSL
               :metrics, :dimensions, :rollups, :find_metric, :find_dimension, to: :main_fact # Runtime

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

    def self.supported_dimension_definitions
      dimension_definitions.all.slice(*dimensions.keys)
    end

    def self.build_dimension_scopes(dimension_names)
      dimension_scopes = Runtime::DimensionScopeCollection.new(dimension_definitions)
      supported_dimension_definitions.slice(*dimension_names).values.flat_map(&:level_objects).each do |level|
        dimension_scopes.register_level(level)
      end
      dimension_scopes
    end
  end
end