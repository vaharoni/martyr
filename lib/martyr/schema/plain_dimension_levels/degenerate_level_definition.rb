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
      attr_accessor :query_level_key, :query_level_with_finder
      attr_reader :loaded

      # @param collection [DimensionDefinitionCollection]
      # @param name [String, Symbol]
      def initialize(collection, name, **options)
        @collection = collection
        hash = {name: name.to_s,
                query_level_key: options[:query_level_key] || name,
                fact_key: options[:fact_key] || "#{dimension_name}_#{name}",
                fact_alias: options[:fact_alias] || "#{dimension_name}_#{name}"}

        hash.merge! label_expression: options[:label_expression] if options[:label_expression]

        super hash

        @query_level_with_finder = options[:query_level_with_finder] || default_query_level_with_finder
        @loaded = false
      end

      def label_key
        nil
      end

      def label_expression
        nil
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
