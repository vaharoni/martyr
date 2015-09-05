module Martyr
  module Runtime
    # This is a SubCube builder. The builder method is #execute.
    # It takes the `select`, `slice`, and `granulate` clauses, makes sure they are well defined, and create a sub cube
    # as a result of their application.
    class QueryContextBuilder

      include Martyr::Translations

      attr_reader :cube

      # TODO: select, slice, and dimensions need to return a new object, so that this is allowed:
      # query1 = cube.slice(:a, with: 1).dimensions(:a)
      # query2 = query1.slice(:b, with: 2)
      # query3 = query1.slice(:b, with: 3)
      # # => Note how query2 and query3 pick up from different stages of the query context build-up

      def initialize(cube)
        @cube = cube
        @select_args = []
        @slice_args = {}
        @granulate_args = []
      end

      # select(:a, :b, :c)
      def select(*arr)
        @select_args += fully_qualify_metrics_array(arr)
        self
      end

      # Variant 1 - full slice as one hash:
      #   slice(metric: :amount, 'artist.name' => {with: 'AC/DC'}, 'genre.name' => {with: 'Rock'}, quantity: {with: '>0'})
      #
      # Variant 2 - on one dimension or metric
      #   slice('artist.name', with: 'AC/DC')
      #
      def slice(*several_variants)
        if several_variants.length == 1 and several_variants.first.is_a?(Hash)
          compound_slice_hash = several_variants.first.stringify_keys.except('metric')
          @slice_args.merge!(compound_slice_hash)
        elsif several_variants.length == 2
          slice_on, slice_definition = several_variants
          @slice_args.merge!(slice_on => slice_definition)
        else
          ArgumentError.new("wrong number of arguments (#{several_variants.length} for 1..2)")
        end
        self
      end

      # granulate('artist.name', 'genre.name')
      def granulate(*arr)
        @granulate_args += arr
        self
      end

      def build
        context = QueryContext.new(@granulate_args)
        context.dimension_scopes = cube.build_dimension_scopes(relevant_dimensions)
        cube.contained_cube_classes.each do |cube_class|
          sub_cube = Runtime::SubCube.new(context, cube_class)
          context.sub_cubes << sub_cube
          sub_cube.set_metrics(@select_args)
          sub_cube.set_slice(@slice_args)
          sub_cube.set_grain(@granulate_args)
          sub_cube.set_defaults_and_dependencies
          sub_cube.slice_all_scopes
        end
        context
      end

      private

      def relevant_dimensions
        level_ids = @slice_args.keys + @granulate_args
        dimensions = level_ids.map{|id| first_element_from_id(id) }.uniq
        return dimensions if dimensions.present?
        cube.supported_dimension_definitions.keys
      end

      def fully_qualify_metrics_array(array)
        array.map do |metric_name|
          with_standard_id(metric_name) do |cube_or_metric, metric|
            metric || add_cube_name_to_metric(cube_or_metric)
          end
        end
      end

      def add_cube_name_to_metric(metric_name)
        cube_classes = cube.contained_cube_classes
        raise Query::Error.new("Invalid metric #{metric_name}: must be preceded with cube name") if cube_classes.length > 1
        "#{cube_classes.first.cube_name}.#{metric_name}"
      end
    end
  end
end