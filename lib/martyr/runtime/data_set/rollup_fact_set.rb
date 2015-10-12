module Martyr
  module Runtime
    class RollupFactSet
      include Martyr::Translations

      attr_reader :cube_name, :metric_id
      delegate :facts, to: :@element

      def initialize(cube_name, metric_id, element)
        @cube_name = cube_name
        @metric_id = standardizer.standardize(metric_id)
        @element = element
      end

      def fetch(id)
        @element[standardizer.standardize(id)]
      end
      alias_method :[], :fetch


      # @return [FactSet]
      def locate(*args, **options)
        new_element = @element.locate(*args, standardizer: standardizer, exclude_metric_ids: metric_id, **options)
        self.class.new(cube_name, metric_id, new_element)
      end

      private

      def standardizer
        @standardizer ||= MetricIdStandardizer.new(@cube_name)
      end

    end
  end
end
