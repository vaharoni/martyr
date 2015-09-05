module Martyr
  module Runtime
    class RollupFactSet

      delegate :facts, :fetch, :[], to: :@element

      def initialize(element)
        @element = element
      end

      # @return [FactSet]
      def slice(*args)

      end

    end
  end
end
