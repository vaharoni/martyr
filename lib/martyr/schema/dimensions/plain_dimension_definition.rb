module Martyr
  module Schema
    class PlainDimensionDefinition
      include ActiveModel::Model
      include Martyr::HasLevelCollection

      attr_accessor :name, :title
      delegate :degenerate_level, :query_level, to: :levels

      # @param name [String]
      # @option title [String]
      def initialize(name, **options, &block)
        super name: name.to_s,
              title: options[:title] || name.to_s.titleize

        @levels = LevelDefinitionCollection.new(dimension: self)
        instance_eval(&block) if block
      end

      def dimension_definition
        self
      end

    end
  end
end