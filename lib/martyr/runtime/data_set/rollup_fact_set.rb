module Martyr
  module Runtime
    class RollupFactSet
      include Martyr::Translations

      attr_reader :cube_name, :metric_id
      delegate :facts, to: :@element

      def initialize(cube_name, metric_id, element)
        @cube_name = cube_name
        @metric_id = standardize_id(metric_id)
        @element = element
      end

      def fetch(id)
        @element[standardize_id(id)]
      end
      alias_method :[], :fetch

      # @return [FactSet]
      def locate(*args, **options)
        new_element = @element.locate(*args, standardize_id: ->(x){standardize_id(x)}, exclude_metric_ids: metric_id, **options)
        self.class.new(cube_name, metric_id, new_element)
      end

      private

      def standardize_id(id)
        with_standard_id(id) do |cube_or_metric_or_dimension, metric_or_level|
          metric_or_level ? id : "#{cube_name}.#{cube_or_metric_or_dimension}"
        end
      end

    end
  end
end
