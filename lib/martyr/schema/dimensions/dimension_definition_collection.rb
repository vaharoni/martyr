module Martyr
  module Schema
    class DimensionDefinitionCollection < HashWithIndifferentAccess
      include Martyr::Registrable

      attr_reader :parent_dimension_definitions
      alias_method :supports_dimension?, :has_key?

      # @param parent_schema_class [Martyr::Base, nil]
      def initialize(parent_schema_class)
        @parent_dimension_definitions = parent_schema_class.try(:dimension_definitions)
      end

      # @return [DimensionDefinition]
      def define_dimension(*args, &block)
        register PlainDimensionDefinition.new(*args, &block)
      end

      # # @param name [String, Symbol]
      # # @param *definition_args [Array] see DimensionDefinition#initialize
      # # @return [SharedDimensionWrapper]
      # def use_shared_dimension(name, *definition_args)
      #   dimension_object = recursive_lookup(name)
      #   raise Schema::Error.new("Cannot find shared dimension `#{name}`") unless dimension_object
      #   register SharedDimensionWrapper.new(dimension_object, *definition_args)
      # end
      #
      # # @see DegenerateDimension#initialize
      # # Passes block to allow level definitions within block
      # def add_degenerate_dimension(name, *args, &block)
      #   register DegenerateDimension.new(name, *args, &block)
      # end
      #
      # def add_time_dimension(name, *args)
      #   register TimeDimension.new(name, *args)
      # end

      # @param name [String, Symbol]
      # @return [DimensionDefinition] object that was found by traversing up the lookup tree
      def recursive_lookup(name)
        fetch(name.to_s, parent_dimension_definitions.try(:recursive_lookup, name.to_s))
      end

      def find_dimension(name)
        recursive_lookup(name) || raise(Schema::Error.new("Could not find dimension `#{name}`"))
      end
      alias_method :find_dimension_definition, :find_dimension
    end
  end
end