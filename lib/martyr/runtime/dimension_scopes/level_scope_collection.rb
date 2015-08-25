module Martyr
  module Runtime
    class LevelScopeCollection < HashWithIndifferentAccess
      include Martyr::LevelCollection

      attr_accessor :sliced_level_i

      def initialize(*args)
        super
        @sliced_level_i = nil
      end

      # @param level [Martyr::Level]
      def register_level(level)
        register level.build(self)
      end

    end
  end
end