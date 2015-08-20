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
      delegate :define_dimension, :find_dimension_definition, to: :dimension_definitions
      delegate :main_fact, :with_main_fact, :with_sub_fact, :build_fact_scopes, to: :fact_definitions
      delegate :metrics, :dimensions, :rollups, :find_metric, :find_dimension, to: :main_fact

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
  end
end