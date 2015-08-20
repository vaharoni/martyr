module Martyr
  module Schema
    class PlainDimensionDefinition
      include ActiveModel::Model
      include Martyr::Schema::HasLevelCollection

      attr_accessor :name, :title
      delegate :degenerate_level, :query_level, :level_and_above_full, :level_and_below_full, to: :levels

      # @param name [String]
      # @option title [String]
      def initialize(name, **options, &block)
        super name: name.to_s,
              title: options[:title] || name.to_s.titleize

        @levels = LevelDefinitionCollection.new(dimension: self)
        instance_eval(&block) if block
      end

    end
  end
end