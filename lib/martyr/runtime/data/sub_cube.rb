module Martyr
  module Runtime
    class SubCube

      attr_reader :cube, :fact_scopes
      delegate :sql, :pretty_sql, :run, to: :fact_scopes

      # @param cube [Martyr::Cube]
      def initialize(cube)
        @cube = cube
        @fact_scopes = cube.build_fact_scopes
      end


    end
  end
end
