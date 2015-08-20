module Martyr
  module Schema
    class DegenerateLevelDefinition < BaseLevelDefinition

      attr_accessor :query_level_key, :query_level_with_finder, :query_level_without_finder, :fact_key, :fact_alias
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
        @query_level_without_finder = options[:query_level_without_finder] || default_query_level_without_finder
        @loaded = false
      end

      def query?
        false
      end

      def degenerate?
        true
      end

      def query_level_below
        @_query_level_below ||= collection.query_level_below(name)
      end

      def slice_with(values)
        query_level_below.send(:decorate_scope) do |scope|
          query_level_with_finder.call(scope, values)
        end
        run
      end

      def slice_without(values)
        query_level_below.send(:decorate_scope) do |scope|
          query_level_without_finder.call(scope, values)
        end
        run
      end

      def all
        @cache
      end

      alias_method :keys, :all

      private

      def default_query_level_with_finder
        ->(scope, values){ scope.where query_level_key => values }
      end

      def default_query_level_without_finder
        ->(scope, values){ scope.where.not query_level_key => values }
      end

      def run
        query_level_below.send(:run)
        @cache = query_level_below.all.map{|x| x.send(query_level_key)}
      end

    end
  end
end