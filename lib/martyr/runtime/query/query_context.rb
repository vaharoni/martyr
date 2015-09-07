module Martyr
  module Runtime
    class QueryContext
      attr_accessor :sub_cubes, :dimension_scopes, :level_ids_in_grain
      delegate :level_scope, :level_scopes, :with_level_scope, :lowest_level_of, :lowest_level_ids_of,
        :levels_and_above_for, :level_ids_and_above_for, :level_loaded?, to: :dimension_scopes

      # @param level_ids_in_grain [Array<String>]
      def initialize(level_ids_in_grain)
        @level_ids_in_grain = level_ids_in_grain
        @sub_cubes = []
      end

      def inspect
        "#<QueryContext sub_cubes=#{sub_cubes}, dimension_levels=#{dimension_scopes}>"
      end

      # = As Dimension Bus Role

      def level_ids_and_above
        level_ids_and_above_for(level_ids_in_grain)
      end

      # @param level_id [String] e.g. 'customers.last_name'
      # @param fact_record [Fact]
      def fetch_unsupported_level_value(level_id, fact_record)
        sought_level_definition = fact_record.sub_cube.definition_from_id(level_id)
        common_denominator_association = fact_record.sub_cube.common_denominator_level_association(level_id, prefer_query: true)
        with_level_scope(common_denominator_association.id) do |common_denominator_level_scope|
          common_denominator_level_scope.recursive_lookup_up fact_record.fact_key_for(common_denominator_association.id), level: sought_level_definition
        end
      end

      # @param level_id [String] e.g. 'customers.last_name'
      # @param fact_key_value [Integer] the primary key stored in the fact
      def fetch_supported_query_level_record(level_id, fact_key_value)
        with_level_scope(level_id) do |level_scope|
          raise Internal::Error.new('level must be query') unless level_scope.query?
          level_scope.recursive_lookup_up fact_key_value, level: level_scope
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
