module Martyr
  module Schema
    class FactDefinitionCollection < HashWithIndifferentAccess
      include ActiveModel::Model
      include Martyr::Registrable

      attr_accessor :cube
      delegate :dimension_definitions, :metric_definitions, to: :cube
      delegate :supports_dimension?, to: :dimension_definitions
      delegate :supports_metric?, to: :metric_definitions

      def main_fact(&scope)
        register MainFactDefinition.new(scope: scope, schema: self)
      end

      def sub_fact(name, propagate, &scope)
        raise Schema::Error.new('`main` is a reserved fact name') if name.to_s == 'main'
        register SubFactDefinition.new(name: name, propagate: propagate, scope: scope, schema: self)
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