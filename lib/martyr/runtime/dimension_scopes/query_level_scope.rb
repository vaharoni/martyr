module Martyr
  module Runtime
    class QueryLevelScope < BaseLevelScope

      delegate :primary_key, :label_key, :label_expression, to: :level

      def initialize(*args)
        super
        @scope = level.scope
      end

      def parent_association_name
        level.parent_association_name_with_default
      end

      def slice_with(values)
        decorate_scope do |scope|
          if label_expression
            scope.where("#{label_expression} IN (?)", values)
          else
            scope.where label_key => values
          end
        end
        execute_query
      end

      def slice_without(values)
        decorate_scope do |scope|
          if label_expression
            scope.where("#{label_expression} NOT IN (?)", values)
          else
            scope.where.not label_key => values
          end
        end
        execute_query
      end

      def loaded?
        !!@cache
      end

      def load
        return true if loaded?
        if !collection.sliced_level_i
          load_from_fact
        elsif to_i > collection.sliced_level_i
          load_from_level_above
        elsif to_i < collection.sliced_level_i
          load_from_level_below
        else
          raise Internal::Error.new("Level `#{name}` is not marked as loaded but it was marked as the slicing level of `#{dimension_name}`")
        end
        true
      end

      def all
        self.load and return cached_values
      end

      def keys
        self.load and return cached_keys
      end

      def fetch(primary_key_value)
        self.load and return @cache[primary_key_value]
      end

      # @param primary_key_value [String, Integer]
      # @param level [BaseLevelScope] this level must be equal or above the current level
      def recursive_value_lookup(primary_key_value, level:)
        record = fetch(primary_key_value)
        return record if name == level.name
        return record.send(level.query_level_key) if level_above.degenerate?

        parent_primary_key_value = record.send(parent_association.foreign_key)
        level_above.recursive_value_lookup(parent_primary_key_value, level: level)
      end

      protected

      def slice_from_fact_keys
        decorate_scope do |scope|
          scope.where primary_key => collection.foreign_keys_from_facts_for(self)
        end
        execute_query
      end

      # Loading strategies

      def load_from_fact
        return slice_from_fact_keys if common_denominator_with_cube.name == name
        common_denominator_with_cube.load_from_fact
        load_from_level_below
      end

      def load_from_level_above
        raise Schema::Error.new("Cannot infer slice for dimension `#{dimension_name}` level `#{name}`: parent level is not query level") unless level_above.query?
        association_primary_key = parent_association.active_record_primary_key
        parent_ids = level_above.all.map { |x| x.send(association_primary_key) }
        set_cache @scope.call.joins(parent_association_name.to_sym).where(parent_association.foreign_key => parent_ids)
      end
      
      def load_from_level_below
        level_below = query_level_below
        raise Schema::Error.new("Cannot infer slice for dimension `#{dimension_name}` level `#{name}`: child level cannot be found") unless level_below

        child_parent_association = level_below.parent_association
        ids_from_child = level_below.all.map { |x| x.send(child_parent_association.foreign_key) }
        set_cache @scope.call.where(child_parent_association.active_record_primary_key => ids_from_child)
      end

      # @return [ActiveRecord::Reflection::AssociationReflection]
      def parent_association
        return nil unless level_above.query?

        relation = @scope.call.klass.reflections[parent_association_name]
        raise Schema::Error.new("Cannot find parent association `#{parent_association_name}` for dimension `#{dimension_name}` level `#{name}`") unless relation
        relation
      end

      def decorate_scope(&block)
        original_scope = @scope
        @scope = Proc.new do
          block.call(original_scope.call)
        end
      end

      def execute_query
        collection.sliced_level_i = to_i
        set_cache @scope.call
      end

      def set_cache(scope)
        @cache = scope.index_by { |x| x.send(primary_key) }
        true
      end

      # @return [Array<ActiveRecord::Base>]
      def cached_values
        @cache.values
      end

      def cached_keys
        @cache.keys
      end
    end
  end
end