module Martyr
  module Schema
    class DegenerateLevelDefinition < BaseLevelDefinition

      attr_accessor :query_level_key, :query_level_with_finder, :query_level_without_finder, :fact_key, :fact_alias
      delegate :query_level_below, to: :collection

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
              query_level_key: options['query_level_key'],
              fact_key: options['fact_key'] || "#{dimension_name}_#{name}",
              fact_alias: options['fact_alias'] || "#{dimension_name}_#{name}"

        @query_level_with_finder = options['query_level_with_finder'] || default_query_level_with_finder
        @query_level_without_finder = options['query_level_without_finder'] || default_query_level_without_finder
      end

      def query?
        false
      end

      private

      def default_query_level_with_finder
      end

      def default_query_level_without_finder
      end

    end
  end
end