module Martyr
  module Schema
    class QueryLevelDefinition < BaseLevelDefinition

      attr_accessor :scope, :primary_key, :label_key, :fact_key, :fact_alias

      # @param collection [DimensionDefinitionCollection]
      # @param name [String, Symbol]
      # @param scope [Proc]
      # @option primary_key [String]
      # @option label_key [String]
      # @option fact_key [String]
      # @option fact_alias [String]
      def initialize(collection, name, scope = nil, **options)
        @collection = collection
        super name: name.to_s,
              primary_key: options['primary_key'] || 'id',
              label_key: options['label_key'] || name.to_s,
              fact_key: options['fact_key'] || "#{dimension_name}_#{name}_id",
              fact_alias: options['fact_alias'] || "#{dimension_name}_#{name}_id"

        @scope = scope || default_scope
      end

      def query?
        true
      end

      private

      # @return [Proc] a lambda object representing running #all on the guessed-class
      def default_scope
        begin
          klass = dimension_name.classify.constantize
          ->{ klass.all }
        rescue => e
          raise Schema::Error.new(e)
        end
      end

    end
  end
end