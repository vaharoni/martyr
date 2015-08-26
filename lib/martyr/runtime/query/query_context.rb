module Martyr
  module Runtime
    class QueryContext

      attr_accessor :sub_cubes, :dimension_scopes

      def initialize
        @sub_cubes = []
        @promises = {}
      end

      def inspect
        "#<QueryContext sub_cubes=#{sub_cubes}, dimensions=#{dimension_scopes}>"
      end

      # = As Dimension Bus Role

      def level_scope(level_id)
        dimension_scopes.find_level(level_id)
      end

      # @param level_id [String]
      # @yieldparam [BaseLevelScope]
      def with_level_scope(level_id)
        yield level_scope(level_id)
      end

      def level_loaded?(level_id)
        level_scope(level_id).loaded?
      end

      def fetch_unsupported_level_value(level_id, fact_record)
        sought_level_definition = fact_record.sub_cube.definition_from_id(level_id)
        common_denominator_association = fact_record.sub_cube.common_denominator_level_association(level_id)
        with_level_scope(common_denominator_association.id) do |common_denominator_level_scope|
          common_denominator_level_scope.recursive_value_lookup fact_record[common_denominator_association.id], level: sought_level_definition
        end
      end

      def fetch_supported_query_level_record(level_id, fact_key_value)
        with_level_scope(level_id) do |level_scope|
          raise Internal::Error.new('level must be query') unless level_scope.query?
          level_scope.recursive_value_lookup fact_key_value, level: level_scope
        end
      end

      def facts
        map_reduce_sub_cubes(&:facts)
      end

      def elements
        map_reduce_sub_cubes(&:elements)
      end

      private

      def map_reduce_sub_cubes
        if sub_cubes.length == 1
          yield sub_cubes.first
        else
          arr = sub_cubes.map do |sub_cube|
            [sub_cube.cube_name, yield(sub_cube)]
          end
          Hash[arr]
        end
      end

    end
  end
end
