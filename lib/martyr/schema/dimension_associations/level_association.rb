module Martyr
  module Schema
    class LevelAssociation
      include Martyr::Level

      attr_accessor :level, :fact_key, :fact_alias
      delegate :dimension_name, to: :collection

      # @param collection [LevelAssociationCollection]
      # @param level [BaseLevelDefinition]
      def initialize(collection, level, fact_key: nil, fact_alias: nil)
        @collection = collection
        @level = level
        @fact_key = fact_key || level.fact_key
        @fact_alias = fact_alias || level.fact_alias
      end

      def supported?
        true
      end

      # Interjects level#build so that the #level object in the appropriate scope object is self
      def build(collection)
        level_scope = level.build(collection)
        level_scope.level = self
        level_scope
      end

      private

      # Delegate everything to level
      def method_missing(method_name, *args, &block)
        level.respond_to?(method_name) ? level.send(method_name, *args, &block) : super
      end

    end
  end
end