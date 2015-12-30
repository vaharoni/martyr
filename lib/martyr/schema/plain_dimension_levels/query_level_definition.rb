module Martyr
  module Schema
    class QueryLevelDefinition < BaseLevelDefinition

      LABEL_EXPRESSION_ALIAS = 'martyr_label_expression'

      attr_accessor :scope, :primary_key, :label_key, :label_expression, :id_method, :record_method, :value_method,
        :parent_association_name

      # @param collection [DimensionDefinitionCollection]
      # @param name [String, Symbol]
      # @param scope [Proc]
      # @option primary_key [String]
      # @option label_key [String]
      # @option fact_key [String]
      # @option fact_alias [String]
      def initialize(collection, name, scope = nil, **options)
        @collection = collection
        @scope = scope || default_scope
        super name: name.to_s,
              primary_key: options[:primary_key] || 'id',
              label_key: options[:label_key] || name.to_s,
              label_expression: options[:label_expression],
              id_method: options[:id_method] || "#{dimension_name}_#{name}_id",
              record_method: options[:record_method] || "#{dimension_name}_#{name}_record",
              value_method: options[:value_method] || "#{dimension_name}_#{name}",
              fact_key: options[:fact_key] || "#{dimension_name}_#{name}_id",
              fact_alias: options[:fact_alias] || "#{dimension_name}_#{name}_id",
              parent_association_name: options[:parent_association_name]

        self.sort = options[:sort] || Sorter.default_for_query(label_field)
        add_label_expression_to_scope
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

      def label_field
        label_expression ? LABEL_EXPRESSION_ALIAS : label_key
      end

      def build(collection)
        Runtime::QueryLevelScope.new(collection, self)
      end

      # @param record [ActiveRecord::Base]
      def record_value(record)
        record.try(label_field)
      end

      # @param mod [Module]
      def register_element_helper_methods(mod)
        level_id = id
        level_definition = self
        mod.module_eval do
          define_method(level_definition.id_method) { key_for(level_id) }
          define_method(level_definition.record_method) { record_for(level_id) }
          define_method(level_definition.value_method) { fetch(level_id) }
        end
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

      def add_label_expression_to_scope
        return unless label_expression
        original_scope = @scope.call
        if original_scope.select_values.present?
          @scope = -> { original_scope.select("#{label_expression} AS #{LABEL_EXPRESSION_ALIAS}") }
        else
          @scope = -> { original_scope.select("#{original_scope.klass.table_name}.*", "#{label_expression} AS #{LABEL_EXPRESSION_ALIAS}") }
        end
      end

    end
  end
end
