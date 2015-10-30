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

      # For reflection
      def dimension?
        true
      end

      def build_data_slice(*args)
        Runtime::PlainDimensionDataSlice.new(self, *args)
      end

      def build_memory_slice(*args)
        Runtime::PlainDimensionMemorySlice.new(self, *args)
      end

    end
  end
end
