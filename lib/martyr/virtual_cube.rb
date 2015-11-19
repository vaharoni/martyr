module Martyr
  class VirtualCube < BaseCube

    def self.contained_cube_classes
      @contained_cube_classes ||= []
    end

    def self.metric_definitions
      @metric_definitions ||= Schema::MetricDefinitionCollection.new(cube_name)
    end

    # = DSL

    def self.use_cube(class_name)
      contained_cube_classes << class_name.constantize
    end

    def self.dimension_definitions
      merge_from_cubes(Schema::DimensionDefinitionCollection.new, &:dimension_definitions)
    end

    def self.supported_dimension_definitions
      merge_from_cubes(Schema::DimensionDefinitionCollection.new, &:supported_dimension_definitions)
    end

    class << self
      delegate :has_custom_rollup, to: :metric_definitions
      delegate :select, :slice, :granulate, :pivot, to: :new_query_context_builder
      alias_method :all, :new_query_context_builder
    end

    # @param mergeable [#merge!]
    def self.merge_from_cubes(mergeable)
      contained_cube_classes.inject(mergeable) do |merged_object, contained_cube|
        merged_object.merge! yield(contained_cube)
      end
    end

    def self.virtual?
      true
    end

  end
end
