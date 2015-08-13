module Martyr
  class Cube

    def self.fact_definitions
      @fact_definitions ||= Schema::FactDefinitionCollection.new(cube: self)
    end

    # @return [Schema::Dimensions::DefinitionCollection]
    def self.dimension_definitions
      @dimension_definitions ||= Schema::DimensionDefinitionCollection.new(parent_schema_class)
    end

    def self.metric_definitions
      @metric_definitions ||= Schema::MetricDefinitionCollection.new
    end

    def self.rollup_definitions
      @rollup_definitions ||= Schema::RollupDefinitionCollection.new
    end

    def self.new_query_context
      Runtime::QueryContext.new(self)
    end

    class << self
      alias_method :dimensions, :dimension_definitions
      alias_method :facts, :fact_definitions
      alias_method :metrics, :metric_definitions
      alias_method :rollups, :rollup_definitions

      delegate :find_dimension, :add_query_dimension, :use_shared_dimension, :add_degenerate_dimension, :add_time_dimension, to: :dimension_definitions
      delegate :main_fact, :sub_fact, to: :fact_definitions
      delegate :find_metric, :add_count_metric, :add_min_metric, :add_max_metric, :add_sum_metric, :add_custom_metric, to: :metric_definitions
      delegate :define_rollup, to: :rollup_definitions

      delegate :select, :slice, :group, :pivot, to: :new_query_context
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