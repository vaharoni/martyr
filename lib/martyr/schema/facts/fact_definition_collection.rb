module Martyr
  module Schema
    class FactDefinitionCollection < HashWithIndifferentAccess
      include Martyr::Registrable

      attr_reader :cube

      def initialize(cube)
        @cube = cube
      end

      def main_fact
        fetch(:main, nil) || build_main_fact
      end

      def build_main_fact
        register MainFactDefinition.new(cube)
      end

      def sub_fact(name, &block)
        raise Schema::Error.new('`main` is a reserved query name') if name.to_s == 'main'
        register SubFactDefinition.new(cube, name, &block)
      end
      alias_method :sub_query, :sub_fact

      # @param selected_sub_facts [Array<String>] array of sub-fact keys to include in the returned collection.
      # @return [Runtime::FactScopeCollection]
      def build_fact_scopes(selected_sub_facts = [])
        selected_sub_facts_hash = Hash[selected_sub_facts.map{|x| [x.to_s, true]}]
        missing_sub_facts = selected_sub_facts_hash.keys - self.keys

        raise Schema::Error.new("Could not find #{'sub query'.pluralize(missing_sub_facts.length)} " +
          missing_sub_facts.join(', ')) if missing_sub_facts.present?

        scope_collection = Runtime::FactScopeCollection.new
        values.each do |scope_definition|
          next unless scope_definition.joins_by_default or selected_sub_facts_hash[scope_definition.name]
          scope_collection.register scope_definition.build
        end
        scope_collection
      end
    end
  end
end
