module Martyr
  module Runtime
    class QueryContext

      attr_reader :cube, :compound_slice

      delegate :execute, to: :new_sub_cube

      # TODO: select, slice, and dimensions need to return a new object, so that this is allowed:
      # query1 = cube.slice(:a, with: 1).dimensions(:a)
      # query2 = query1.slice(:b, with: 2)
      # query3 = query1.slice(:b, with: 3)
      # # => Note how query2 and query3 pick up from different stages of the query context build-up

      def initialize(cube)
        @cube = cube
        @metric_names = []
        @dimension_names = []
        @compound_slice = CompoundSlice.new(mart)
      end

      def select(*metric_names)
        @metric_names += metric_names
        @metric_names.uniq!
        self
      end

      def slice(*args)
        @compound_slice.slice(*args)
        self
      end

      def dimensions(*dimension_names)
        @dimension_names += dimension_names
        @dimension_names.uniq!
        self
      end

      private

      # @return [CubeSlice]
      def new_sub_cube
        SubCube.new(self)
      end

      # @return [FactScopeCollection]
      def build_fact_scope_context
        cube.fact_definitions.build_fact_scopes
      end
    end
  end
end