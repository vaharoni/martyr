module Martyr
  module Runtime
    # This is a SubCube builder. The builder method is #execute.
    # It takes the `select`, `slice`, and `granulate` clauses, makes sure they are well defined, and create a sub cube
    # as a result of their application.
    class QueryContext

      attr_reader :cube

      # TODO: select, slice, and dimensions need to return a new object, so that this is allowed:
      # query1 = cube.slice(:a, with: 1).dimensions(:a)
      # query2 = query1.slice(:b, with: 2)
      # query3 = query1.slice(:b, with: 3)
      # # => Note how query2 and query3 pick up from different stages of the query context build-up

      def initialize(cube)
        @cube = cube
        @select_args = []
        @slice_args = []
        @granulate_args = []
      end

      def select(*args)
        @select_args += args.flatten
        self
      end

      def slice(*args)
        @slice_args << args
        self
      end

      def granulate(hash)
        @granulate_args << hash
        self
      end

      # @return [Runtime::SubCube]
      def execute
        sub_cube = build_sub_cube
        sub_cube.slice_all_scopes
        sub_cube
      end

      def build_sub_cube
        sub_cube = SubCube.new(cube)
        sub_cube.set_metrics(@select_args)
        sub_cube.set_slice(@slice_args)
        sub_cube.set_grain(@granulate_args)
        sub_cube.set_defaults_and_dependencies
        sub_cube
      end

    end
  end
end