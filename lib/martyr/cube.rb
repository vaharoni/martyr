module Martyr
  class Cube < BaseCube
    extend Martyr::Translations

    def self.contained_cube_classes
      [self]
    end

    def self.fact_definitions
      @fact_definitions ||= Schema::FactDefinitionCollection.new(self)
    end

    # @return [Schema::Dimensions::DefinitionCollection]
    def self.dimension_definitions
      return @dimension_definitions if @dimension_definitions
      @dimension_definitions = Schema::DimensionDefinitionCollection.new
      @dimension_definitions.merge! parent_schema_class.dimension_definitions if parent_schema_class.present?
      @dimension_definitions
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
               :has_sum_metric, :has_custom_metric, :has_custom_rollup, :main_query, # DSL
               :metrics, :find_metric, :dimension_associations, to: :main_fact # Runtime

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

    # @param level_ids [Array<String>]
    # @return [Array<String>] all ids that are supported by the cube through the dimension
    def self.select_supported_level_ids(level_ids)
      dimension_names = supported_dimension_definitions.keys
      level_ids.select{|id| dimension_names.include? first_element_from_id(id) }
    end

    def self.level_associations
      dimension_associations.flat_map { |_name, dimension_association| dimension_association.level_objects }
    end

  end
end
