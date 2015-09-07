module Martyr
  module Runtime
    class LevelScopeCollection < HashWithIndifferentAccess
      include Martyr::LevelCollection

      attr_accessor :bottom_level_sliced_i

      def initialize(*args)
        super
        @bottom_level_sliced_i = nil
      end

      # @param level [Martyr::Level]
      def register_level(level)
        register level.build(self)
      end

    end
  end
end
