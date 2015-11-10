module Martyr
  module Schema
    class DegenerateLevelDefinition < BaseLevelDefinition

      # @attribute query_level_key [String] the field in the query level where the degenerate attribute resides. E.g.:
      #   degenerate_level :country, query_level_key: 'billing_country'
      #
      # @attribute query_level_with_finder [Proc] the block to run on the query level's ActiveRecord scope. The block
      #   receives two arguments - `scope` and `values`. E.g.:
      #   ->(scope, values) { scope.where('billing_country' => values) }
      #
      # @attribute fact_key [String] the field in the fact where the degenerate attribute resides. E.g.:
      #   degenerate_level :country, fact_key: 'invoices.country'
      #
      # @attribute fact_alias [String] the alias to give in the `AS` part of the SQL fact statement.
      #
      attr_accessor :query_level_key, :query_level_with_finder, :fact_key, :fact_alias
      attr_reader :loaded

      # @param collection [DimensionDefinitionCollection]
      # @param name [String, Symbol]
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
