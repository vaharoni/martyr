module Martyr
  module Schema
    class DegenerateLevelDefinition < BaseLevelDefinition

      attr_accessor :query_level_key, :query_level_with_finder, :fact_key, :fact_alias
      attr_reader :loaded

      # @param collection [DimensionDefinitionCollection]
      # @param name [String, Symbol]
      # @option query_level_key [String]
      # @option :query_level_with_finder [Proc]
      # @option :query_level_without_finder [Proc]
      # @option fact_key [String]
      # @option fact_alias [String]
      def initialize(collection, name, **options)
        @collection = collection
        super name: name.to_s,
              query_level_key: options[:query_level_key] || name,
              fact_key: options[:fact_key] || "#{dimension_name}_#{name}",
              fact_alias: options[:fact_alias] || "#{dimension_name}_#{name}"

        @query_level_with_finder = options[:query_level_with_finder] || default_query_level_with_finder
        @loaded = false
      end

      def query?
        false
      end

      def degenerate?
        true
      end

      def build(collection)
        Runtime::DegenerateLevelScope.new(collection, self)
      end

      private

      def default_query_level_with_finder
        ->(scope, values){ scope.where query_level_key => values }
      end

    end
  end
end
