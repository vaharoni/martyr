module Martyr
  class BaseCube
    extend Martyr::Translations

    def self.set_cube_name(value)
      @name = value.to_s
    end

    def self.cube_name
      @name || name.split('::').last.underscore
    end

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

    def self.find_metric(metric_name)
      raise NotImplementedError
    end

    # @param metric_id [String] fully qualified metric ID
    # @return [MetricDefinition]
    def self.find_metric_id(metric_id)
      cube_name, metric_name = id_components(metric_id)
      raise(Schema::Error.new "Metric for cube `#{cube_name}` was asked for cube `#{self.cube_name}`") unless
        cube_name == self.cube_name

      find_metric(metric_name)
    end

    # @param metric_id [String] fully qualified metric ID
    # @return [Boolean]
    def self.metric?(metric_id)
      find_metric_id(metric_id).present? rescue false
    end
  end
end
