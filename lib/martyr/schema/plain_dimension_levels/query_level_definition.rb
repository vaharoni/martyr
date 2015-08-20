module Martyr
  module Schema
    class QueryLevelDefinition < BaseLevelDefinition

      attr_accessor :scope, :primary_key, :label_key, :fact_key, :fact_alias, :parent_association_name
      attr_reader :loaded

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
              primary_key: options[:primary_key] || 'id',
              label_key: options[:label_key] || name.to_s,
              fact_key: options[:fact_key] || "#{dimension_name}_#{name}_id",
              fact_alias: options[:fact_alias] || "#{dimension_name}_#{name}_id",
              parent_association_name: options[:parent_association_name]

        @scope = scope || default_scope
        @loaded = false
      end

      def query?
        true
      end

      def degenerate?
        false
      end

      def parent_association_name_with_default
        (parent_association_name || level_above.try(:name)).to_s.presence
      end

      def slice_with(values)
        decorate_scope do |scope|
          scope.where label_key => values
        end
        run
      end

      def slice_without(values)
        decorate_scope do |scope|
          scope.where.not label_key => values
        end
        run
      end

      def all
        @loaded ? cached_values : infer_slice
      end

      def keys
        all.map{|x| x.send(primary_key)}
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

      def decorate_scope(&block)
        original_scope = @scope
        @scope = Proc.new do
          block.call(original_scope.call)
        end
      end

      # @return [ActiveRecord::Reflection::AssociationReflection]
      def parent_association
        return nil unless level_above.query?

        relation = scope.call.klass.reflections[parent_association_name_with_default]
        raise Schema::Error.new("Cannot find parent association `#{parent_association_name.to_s}` for dimension `#{dimension_name}` level `#{name}`") unless relation
        relation
      end

      def run
        set_cache @scope.call
      end

      def infer_slice
        raise Schema::Error.new("Cannot infer slice for dimension `#{dimension_name}` level `#{name}`: parent level is not query level") unless level_above.query?
        association_primary_key = parent_association.active_record_primary_key
        parent_ids = level_above.all.map{|x| x.send(association_primary_key)}
        set_cache scope.call.joins(parent_association_name).where(parent_association.foreign_key => parent_ids)
      end

      def set_cache(scope)
        @cache = scope.index_by{|x| x.send(primary_key)}
        @loaded = true
        cached_values
      end

      def cached_values
        @cache.values
      end

    end
  end
end