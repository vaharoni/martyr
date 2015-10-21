module Martyr
  module Runtime
    module HasScopedLevels

      def scope(supported_level_ids)
        dup.scope!(supported_level_ids)
      end

      protected

      def scope!(supported_level_ids)
        @supported_level_ids = Array.wrap(supported_level_ids)
        @scoped_levels = nil
        self
      end

      private

      def scoped_levels
        return levels unless @supported_level_ids.present?
        return @scoped_levels if @scoped_levels
        unsupported_keys = levels.keys - @supported_level_ids
        supported_keys = levels.keys - unsupported_keys
        @scoped_levels = levels.slice(*supported_keys)
      end

    end
  end
end
