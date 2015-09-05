module Martyr
  module Runtime
    class QueryLevelScope < BaseLevelScope

      delegate :record_value, :primary_key, :label_key, :label_expression, to: :level

      def initialize(*args)
        super
        @scope = level.scope
      end

      def parent_association_name
        level.parent_association_name_with_default
      end

      def nullify
        decorate_scope do |scope|
          scope.where('0=1')
        end
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
          execute_query
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

      # @return [ActiveRecord::Base]
      def fetch(primary_key_value)
        self.load and return @cache[primary_key_value]
      end

      # TODO: this is making the assumption that only degenerate levels can be above a query level
      # This method allows finding the value of the level identified in `level` that is the parent of the record in the
      # current level object that is identified by `primary_key_value`. It traversed the hierarchy UP until reaching
      # the desired `level`.
      #
      # @param primary_key_value [String, Integer]
      # @param level [Martyr::Level] this level must be equal or above the current level
      # @return [ActiveRecord::Base, String] the record if query level, or the value if degenerate
      def recursive_value_lookup_up(primary_key_value, level:)
        record = fetch(primary_key_value)
        return record if name == level.name
        return record.send(level.query_level_key) if level_above.degenerate?

        level_above.recursive_value_lookup_up(record_parent_primary_key(record), level: level)
      end

      # TODO: this is making the assumption that only degenerate levels can be above a query level
      # @param records [Array<String>, String, Array<ActiveRecord::Base>, ActiveRecord::Base] two options:
      #   - Single or Array of values as evaluated by the level value strategy, e.g. 'invoice-1'
      #   - Single or Array of active record objects - this helps DRYing up code in this package that already obtained records
      # @param level [Martyr::Level] this level must be equal or below the current level
      # @return [Array<ActiveRecord::Base>, Array<String>]
      def recursive_value_lookup_down(records, level:)
        records = Array.wrap(records)
        records = records.flat_map{|value| cached_records_by_value[value]} if records.first.is_a?(String)

        return records if name == level.name
        return records.map{|r| r.send(level.query_level_key)}.uniq if level.degenerate?
        child_records = level_below.fetch_by_parent(records.map{|x| record_primary_key(x)})
        level_below.recursive_value_lookup_down(child_records, level: level)
      end

      protected

      # @param parent_primary_key_values [Array<Integer>]
      # @return [Array<ActiveRecord::Base>] all records whose parent keys were given in parent_primary_key_values
      def fetch_by_parent(parent_primary_key_values)
        self.load and return Array.wrap(parent_primary_key_values).flat_map{|primary_key_value| cached_records_by_parent[primary_key_value]}
      end

      # TODO: inject one cube if exists

      # def slice_from_fact_keys
      #   decorate_scope do |scope|
      #     scope.where primary_key => collection.foreign_keys_from_facts_for(self)
      #   end
      #   execute_query
      # end

      # Loading strategies

      # def load_from_fact
      #   return slice_from_fact_keys if common_denominator_with_cube.name == name
      #   common_denominator_with_cube.load_from_fact
      #   load_from_level_below
      # end

      def load_from_level_above
        raise Schema::Error.new("Cannot infer slice for dimension `#{dimension_name}` level `#{name}`: parent level is not query level") unless level_above.query?
        parent_ids = level_above.all.map { |x| level_above.record_primary_key(x) }
        set_cache @scope.call.joins(parent_association_name.to_sym).where(parent_association.foreign_key => parent_ids)
      end
      
      def load_from_level_below
        level_below = query_level_below
        raise Schema::Error.new("Cannot infer slice for dimension `#{dimension_name}` level `#{name}`: child level cannot be found") unless level_below

        ids_from_child = level_below.all.map { |x| level_below.record_parent_primary_key(x) }
        set_cache @scope.call.where(primary_key => ids_from_child)
      end

      # TODO: this is making the assumption that only degenerate levels can be above a query level
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
        @cache = scope.index_by { |x| record_primary_key(x) }
        true
      end

      # @return [Array<ActiveRecord::Base>]
      def cached_values
        @cache.values
      end

      def cached_keys
        @cache.keys
      end

      # @return [Hash] { parent_key1 => Array<ActiveRecord::Base> }
      def cached_records_by_parent
        cached_records_by(parent_association.foreign_key)
      end

      # @return [Hash] { value1 => Array<ActiveRecord::Base> }
      def cached_records_by_value
        cached_records_by(level.label_field)
      end

      public

      # @return [Hash] { key1 => Array<ActiveRecord::Base>, key2 => Array<ActiveRecord::Base> }
      def cached_records_by(key)
        self.load
        @cached_records_by ||= {}
        return @cached_records_by[key] if @cached_records_by[key]
        @cached_records_by[key] = cached_values.group_by{|x| x.send(key)}
      end

      def record_primary_key(record)
        record.send(primary_key)
      end

      def record_parent_primary_key(record)
        record.send(parent_association.foreign_key)
      end
    end
  end
end