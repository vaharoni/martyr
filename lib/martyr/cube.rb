module Martyr
  class Cube < BaseCube
    extend Martyr::Translations

    def self.contained_cube_classes
      [self]
    end

    def self.fact_definitions
      @fact_definitions ||= Schema::FactDefinitionCollection.new(self)
    end

    # Return all dimension definitions regardless of whether they are supported by the cube.
    # A cube +supports+ a dimension only if it calls the #has_dimension_level DSL method.
    # It is quite typical to have multiple cubes inherenting from a context with shared dimensions.
    # So it is typical to have cubes that maintain a reference to a dimension definition they do not support.
    #
    # @see #supported_dimension_definitions to get only the supported dimensions.
    #
    # In the example below, Cube1 does not support shared_dimension_2:
    #
    #   class Common < Martyr::Cube
    #     define_dimension :shared_dimension_1 do
    #       ...
    #     end
    #
    #     define_dimension :shared_dimension_2 do
    #       ...
    #     end
    #   end
    #
    #   class Cube1 < Common
    #     has_dimension_level :shared_dimension_1, :level1
    #   end
    #
    #   Cube1.dimension_definitions.keys
    #   # => ['shared_dimension_1', 'shared_dimension_2']
    #
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

    # @see comment for #dimension_definitions
    #
    # @return [Hash] { dimension_name => PlainDimensionDefinition } including dimensions that have at least one level
    #   supported by the cube through #has_dimension_level
    def self.supported_dimension_definitions
      dimension_definitions.all.slice(*dimension_associations.keys)
    end

    # Helper methods used to filter out unsupported +dimensions+.
    # It does not apply understanding of dimension hierarchy. If a dimension has 3 levels: L1, L2, L3, and the cube
    # called #has_dimension_level on L2, all levels L1, L2, L3 will pass the filter, despite the more detailed L3
    # is not supported in the cube grain.
    #
    # @param level_ids [Array<String>]
    # @return [Array<String>] all ids that are supported by the cube through the dimension
    def self.select_supported_level_ids(level_ids)
      dimension_names = supported_dimension_definitions.keys
      level_ids.select{|id| dimension_names.include? first_element_from_id(id) }
    end

    # Return all levels that are directly connected to the cube with #has_dimension_level.
    #
    # @return [Array<LevelAssociation>]
    def self.level_associations
      dimension_associations.flat_map { |_name, dimension_association| dimension_association.level_objects }
    end

  end
end
