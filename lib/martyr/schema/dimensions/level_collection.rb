module Martyr
  module Schema
    class LevelCollection < HashWithIndifferentAccess
      include Registrable

      attr_reader :dimension_name

      # @param dimension_name [String]
      def initialize(dimension_name)
        @dimension_name = dimension_name
      end

      def add_level(name, **args)
        register Level.new(name, dimension_name: dimension_name, **args)
      end

    end
  end
end