module Martyr
  module Runtime
    class QueryContext

      attr_reader :cube, :compound_slice, :metrics, :dimensions

      delegate :execute, to: :new_sub_cube

      # TODO: select, slice, and dimensions need to return a new object, so that this is allowed:
      # query1 = cube.slice(:a, with: 1).dimensions(:a)
      # query2 = query1.slice(:b, with: 2)
      # query3 = query1.slice(:b, with: 3)
      # # => Note how query2 and query3 pick up from different stages of the query context build-up

      def initialize(cube)
        @cube = cube
        @metrics = []
        @dimensions = []
        @compound_slice = CompoundSlice.new(cube)
      end

      def select(*metric_names)
        @metrics += metric_names.map {|name| cube.find_metric(name)}
        @metrics.uniq!(&:name)
        self
      end

      def slice(*args)
        @compound_slice.slice(*args)
        self
      end

      def group(*dimension_names)
        @dimensions += dimension_names.map {|name| cube.find_dimension(name)}
        @dimensions.uniq!(&:name)
        self
      end

      private

      # @return [CubeSlice]
      def new_sub_cube
        SubCube.new(self)
      end

      # Builds a fresh new fact scope collection based on the fact scope definitions
      # @return [FactScopeCollection]
      def build_fact_scope_context
        cube.fact_definitions.build_fact_scopes
      end
    end
  end
end