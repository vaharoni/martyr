module Martyr
  module Runtime
    class FactSet

      attr_reader :sub_cube, :facts

      def initialize(sub_cube, facts)
        @sub_cube = sub_cube
        @facts = facts
      end

    end
  end
end