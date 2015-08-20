module Martyr
  module Schema
    class FactDefinitionCollection < HashWithIndifferentAccess
      include Martyr::Registrable

      attr_reader :cube

      def initialize(cube)
        @cube = cube
      end

      # = DSL

     def with_main_fact(&block)
        register MainFactDefinition.new(cube, &block)
      end

      def with_sub_fact(name, **args, &scope)
        raise Schema::Error.new('`main` is a reserved fact name') if name.to_s == 'main'
        register SubFactDefinition.new(name: name, cube: cube, scope: scope, **args)
      end

      def main_fact
        fetch(:main, nil)
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