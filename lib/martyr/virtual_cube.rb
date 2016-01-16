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
      delegate :find_metric, :has_custom_rollup, to: :metric_definitions
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

    # @override
    def self.find_metric_id(metric_id)
      cube_name, metric_name = id_components(metric_id)
      if cube_name == self.cube_name
        find_metric(metric_name)
      else
        find_cube(cube_name).find_metric(metric_name)
      end
    end

    def self.find_cube(cube_name)
      contained_cube_classes.find{ |cube| cube.cube_name == cube_name } ||
        raise(Schema::Error.new "Could not find `#{cube_name}`")
    end
  end
end
