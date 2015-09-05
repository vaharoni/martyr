module Martyr
  module Runtime
    class Element < HashWithIndifferentAccess

      attr_reader :facts, :grain, :sub_cube_slice

      # @param grain [Hash] {level_name => level_value}
      # @param facts [Array<Fact>]
      # @param sub_cube_slice [SubCubeSlice]
      def initialize(grain, facts, sub_cube_slice)
        @facts = facts
        @grain = grain
        @sub_cube_slice = sub_cube_slice
        merge! grain
      end

      # @param metrics [Array<BaseMetric>]
      def rollup(*metrics)
        metrics.each do |metric|
          store metric.id, metric.rollup(facts)
        end
      end

      def coordinates
        sub_cube_slice
        sub_cube_slice.merge_with_hash(grain_coordinates).to_hash
      end

      private

      def grain_coordinates
        grain.map do |level_id, value|
          {level_id => {'with' => value}}
        end.inject({}) do |h, coords|
          h.merge! coords
        end
      end

    end
  end
end