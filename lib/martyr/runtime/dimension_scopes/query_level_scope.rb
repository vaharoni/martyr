module Martyr
  module Runtime
    class QueryLevelScope < BaseLevelScope

      delegate :primary_key, :label_key, to: :level

      def initialize(*args)
        super
        @scope = level.scope
      end

      def parent_association_name
        level.parent_association_name_with_default
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

      def decorate_scope(&block)
        original_scope = @scope
        @scope = Proc.new do
          block.call(original_scope.call)
        end
      end

      # @return [ActiveRecord::Reflection::AssociationReflection]
      def parent_association
        return nil unless level_above.query?

        relation = @scope.call.klass.reflections[parent_association_name]
        raise Schema::Error.new("Cannot find parent association `#{parent_association_name}` for dimension `#{dimension_name}` level `#{name}`") unless relation
        relation
      end

      def run
        set_cache @scope.call
      end

      def infer_slice
        raise Schema::Error.new("Cannot infer slice for dimension `#{dimension_name}` level `#{name}`: parent level is not query level") unless level_above.query?
        association_primary_key = parent_association.active_record_primary_key
        parent_ids = level_above.all.map{|x| x.send(association_primary_key)}
        set_cache @scope.call.joins(parent_association_name.to_sym).where(parent_association.foreign_key => parent_ids)
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