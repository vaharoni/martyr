module Martyr
  module Schema
    class FactDefinitionCollection < HashWithIndifferentAccess
      include Martyr::Registrable

      attr_reader :cube

      def initialize(cube)
        @cube = cube
      end

      def with_sub_fact(name, **args, &scope)
        raise Schema::Error.new('`main` is a reserved fact name') if name.to_s == 'main'
        register SubFactDefinition.new(name: name, cube: cube, scope: scope, **args)
      end

      def main_fact
        fetch(:main, nil) || build_main_fact
      end

      def build_main_fact
        register MainFactDefinition.new(cube)
      end

      # @return [Runtime::FactScopeCollection]
      def build_fact_scopes
        scope_collection = Runtime::FactScopeCollection.new
        values.each do |scope_definition|
          scope_collection.register scope_definition.build
        end
        scope_collection
      end
    end
  end
end