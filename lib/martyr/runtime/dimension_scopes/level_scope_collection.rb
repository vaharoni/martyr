module Martyr
  module Runtime
    class LevelScopeCollection < HashWithIndifferentAccess
      include Martyr::LevelCollection

      attr_reader :dimension_supported

      def initialize(*args)
        super
        @dimension_supported = false
      end

      # @param level [Martyr::Level]
      def register_level(level)
        @dimension_supported = true if level.supported?
        register level.build(self)
      end

      def build_slice
        Runtime::PlainDimensionSlice.new(dimension)
      end

      # = Filters

      # @return [Array<Martyr::Level>]
      def supported_levels
        return nil unless dimension_supported
        level_objects.select(&:supported?)
      end

      # = Finders

      # @param level_name [String, Symbol]
      # @return [Array<Martyr::Level>] the first level of type `query` below the provided level
      def query_level_below(level_name)
        level_objects[level_index(level_name) + 1..-1].find{|level| level.query?}
      end

      # @param level_name [String, Symbol]
      # @return [Array<Martyr::Level>] the provided level and all the levels above it
      def level_and_above_full(level_name)
        level_objects[0..level_index(level_name)]
      end

      # @param level_name [String, Symbol]
      # @return [Array<Martyr::Level>] the provided level and all the levels below it
      def level_and_below_full(level_name)
        level_objects[level_index(level_name)..-1]
      end

      # = Finders for selected filter

      # @return [Array<Martyr::Level>]
      def level_and_above_supported(level_name)
        level_and_above_full(level_name).select(&:supported?)
      end

      # @return [Array<Martyr::Level>]
      def level_and_below_supported(level_name)
        level_and_below_full(level_name).select(&:supported?)
      end
    end
  end
end