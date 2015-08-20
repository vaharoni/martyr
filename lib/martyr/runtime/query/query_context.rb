module Martyr
  module Runtime
    # This is a SubCube builder. The builder method is #execute.
    # It takes the `select`, `slice`, and `granulate` clauses, makes sure they are well defined, and create a sub cube
    # as a result of their application.
    class QueryContext

      attr_reader :cube, :compound_slice, :metrics, :grain

      # TODO: select, slice, and dimensions need to return a new object, so that this is allowed:
      # query1 = cube.slice(:a, with: 1).dimensions(:a)
      # query2 = query1.slice(:b, with: 2)
      # query3 = query1.slice(:b, with: 3)
      # # => Note how query2 and query3 pick up from different stages of the query context build-up

      def initialize(cube)
        @cube = cube
        @metrics = []
        @grain = QueryGrain.new(cube)
        @compound_slice = CompoundSlice.new(cube)
      end

      def select(*metric_names)
        @metrics += metric_names.map{|metric_name| cube.find_metric(metric_name) }
        @metrics.uniq!(&:name)
        self
      end

      def slice(*args)
        @compound_slice.slice(*args)
        self
      end

      def granulate(grain_hash)
        grain_hash.each do |dimension, level|
          @grain.add_granularity(dimension, level)
        end
        self
      end

      # @return [Runtime::SubCube]
      def execute
        compound_slice.add_to_grain(@grain)
        @grain.set_all_if_empty

        sub_cube = SubCube.new(cube)
        grain.add_to_select(sub_cube.fact_scopes)
        metrics.each {|metric| metric.add_to_select(sub_cube.fact_scopes) }
        compound_slice.add_to_where(sub_cube.fact_scopes)
        grain.add_to_group_by(sub_cube.fact_scopes)

        sub_cube
      end

    end
  end
end