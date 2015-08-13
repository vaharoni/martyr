module Martyr
  module Schema
    class QueryDimension < DimensionDefinition
      include Martyr::HasScope
      include Martyr::Schema::BuildsQueryDimensionSlice

      validates_presence_of :scope_query
      validate :scope_valid

      attr_accessor :primary_key, :label_key
      attr_reader :scope

      # @param name [Symbol, String]
      # @option scope [Lambda] lambda function to define the dimension scope
      def initialize(name, scope = nil, primary_key: 'id', label_key: 'name', fact_key: "#{name}_id", fact_alias: nil)
        super(name: name.to_s, primary_key: primary_key, label_key: label_key, fact_key: fact_key,
              fact_alias: normalize_alias(fact_alias || "#{name}_id")) do
          @scope = scope || default_scope
        end
      end

      private

      # @return [Proc] a lambda object representing running #all on the guessed-class
      def default_scope
        begin
          klass = name.classify.constantize
          ->{ klass.all }
        rescue => e
          raise Schema::Error.new(e)
        end
      end

      # @validation
      def scope_valid
        errors.add(:scope, 'Invalid scope provided') unless scope_query.present?
      end

    end
  end
end