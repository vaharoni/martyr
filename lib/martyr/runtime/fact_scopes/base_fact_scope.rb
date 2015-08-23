module Martyr
  module Runtime
    class BaseFactScope
      attr_reader :fact_definition, :scope
      delegate :name, :supports_metric?, :supports_dimension_level?, to: :fact_definition

      # = Scope accessors

      # @param fact_definition [Schema::MainFactDefinition]
      def initialize(fact_definition)
        @fact_definition = fact_definition
        @scope = fact_definition.scope
      end

      def run_scope
        scope.call
      end

      def scope_sql
        run_scope.try(:arel).try(:to_sql)
      end

      def null?
        @scope.is_a?(NullScope)
      end

      def set_null_scope
        @scope = NullScope.new
      end

      # = Scope support check

      # TODO: Consider refactoring: check for metric support might be all I need.
      def decorate_if_supports(metric_name: nil, dimension_name: nil, level_name: nil, &block)
        if metric_name
          if_supports_metric(metric_name) { decorate_scope(&block) }
        elsif dimension_name and level_name
          if_supports_dimension_level(dimension_name, level_name) { decorate_scope(&block) }
        else
          raise Internal::Error.new('Invalid arguments for if_supports: `level_name` cannot be empty') unless level_name
          raise Internal::Error.new('Invalid arguments for if_supports: `dimension_name` cannot be empty') unless dimension_name
        end
      end

      # = Scope updater

      # Decorator pattern. The block must return a new scope.
      # @example
      #   Let @scope be: -> { Invoice.all }
      #
      #   decorate_scope {|scope| scope.where(id: 5)}
      #
      #   @scope is now: -> { ->{ Invoice.all }.call.where(id: 5) }
      #
      #   decorate_scope {|scope| scope.where.not(id: 7)}
      #
      #   @scope is now: -> { -> { ->{ Invoice.all }.call.where(id: 5) }.call.where.not(id: 7) }
      #
      def decorate_scope(&block)
        return if null?
        original_scope = self.scope
        @scope = Proc.new do
          block.call(original_scope.call, self)
        end
      end

      # @param level [LevelAssociation]
      # @return [String] how to add a where condition to the level - different depending on whether this is a main fact
      #   scope or sub fact
      def level_key_for_where(level)
        raise NotImplementedError
      end

      private

      def if_supports_metric(*args, &block)
        raise NotImplementedError
      end

      def if_supports_dimension_level(*args, &block)
        raise NotImplementedError
      end

    end
  end
end