module Martyr
  module Schema
    class DimensionDefinitionCollection < HashWithIndifferentAccess
      include Martyr::Translations
      include Martyr::Registrable

      alias_method :supports_dimension?, :has_key?
      alias_method :find_dimension, :find_or_error
      alias_method :all, :to_hash

      # @return [DimensionDefinition]
      def define_dimension(*args, &block)
        register PlainDimensionDefinition.new(*args, &block)
      end

      def find_level_definition(level_id)
        with_standard_id(level_id) { |dimension, level| find_dimension(dimension).find_level(level) }
      end

      # # @param name [String, Symbol]
      # # @return [DimensionDefinition] object that was found by traversing up the lookup tree
      # def recursive_lookup(name)
      #   fetch(name.to_s, parent_dimension_definitions.try(:recursive_lookup, name.to_s))
      # end
      #
      # def find_dimension(name)
      #   recursive_lookup(name) || raise(Schema::Error.new("Could not find dimension `#{name}`"))
      # end
      #

      # # @return [Hash] { dimension_name => PlainDimensionDefinition } including dimension definitions from all superclasses
      # def all
      #   return to_hash unless parent_dimension_definitions
      #   to_hash.merge(parent_dimension_definitions.all)
      # end

    end
  end
end
