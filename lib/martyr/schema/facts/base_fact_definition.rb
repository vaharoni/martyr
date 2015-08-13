module Martyr
  module Schema
    class BaseFactDefinition
      include ActiveModel::Model

      # TODO: :dimension_definitions is currently brought here so that I can use it for validations of propagate

      # @attribute schema [#supports_dimension?, #supports_metric?]
      attr_accessor :name, :scope, :schema
      delegate :supports_dimension?, :supports_metric?, to: :schema

      # @return [Runtime::FactScope]
      def build
        Runtime::FactScope.new(self)
      end

    end
  end
end