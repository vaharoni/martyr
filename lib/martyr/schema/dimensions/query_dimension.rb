module Martyr
  module Schema
    class QueryDimension < DimensionDefinition
      include ActiveModel::Validations
      include HasScope

      validates_presence_of :scope_query
      validate :scope_valid

      attr_reader :scope

      # @param name [Symbol, String]
      # @option scope [Lambda] lambda function to define the dimension scope
      # @optio levels [Array<String>]
      def initialize(name, scope = nil, **level_params, &block)
        super(name, **level_params, &block)

        @scope = scope || default_scope
        raise "#{name} dimension is invalid: #{errors.full_messages.join('; ')}" unless valid?
      rescue => e
        raise Schema::Error.new(e)
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