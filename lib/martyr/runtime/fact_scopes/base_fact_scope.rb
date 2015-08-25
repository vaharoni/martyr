module Martyr
  module Runtime
    class BaseFactScope
      attr_reader :fact_definition, :scope
      delegate :name, :supports_metric?, :supports_dimension_level?, :dimensions, to: :fact_definition

      # = Scope accessors

      # @param fact_definition [Schema::MainFactDefinition]
      def initialize(fact_definition)
        @fact_definition = fact_definition
        @scope = fact_definition.scope
      end

      def run_scope
        @_run_scope ||= scope.call
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

      # @return [String] how to add a where condition to the level
      def level_key_for_where(level_id)
        fact_definition.find_level_association(level_id).fact_key
      end

      # = Scope support check

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

    end
  end
end