module Martyr
  module Runtime
    class QueryContext
      include Martyr::Translations

      attr_accessor :sub_cubes_hash, :dimension_scopes, :level_ids_in_grain
      attr_reader :data_slice
      delegate :level_scope, :level_scopes, :with_level_scope, :lowest_level_of, :lowest_level_ids_of,
        :levels_and_above_for, :level_ids_and_above_for, :level_loaded?, to: :dimension_scopes

      def initialize
        @data_slice = DataSlice.new(self)
        @sub_cubes_hash = {}
      end

      def inspect
        "#<QueryContext grain: #{level_ids_in_grain}, memory_slice: #{memory_slice.to_hash}, data_slice: #{data_slice.to_hash}, sub_cubes: #{sub_cubes}>"
      end

      def sub_cubes
        sub_cubes_hash.values
      end

      # = Run

      def facts
        map_reduce_sub_cubes(&:facts)
      end

      def elements(*args)
        map_reduce_sub_cubes{|x| x.elements(*args)}
      end

      # = Memory slices

      def memory_slice
        @memory_slice ||= MemorySlice.new(data_slice)
      end

      def slice(*args)
        memory_slice.slice(*args)
        self
      end

      # = Dispatcher

      # @return [BaseMetric, DimensionReference, BaseLevelDefinition]
      def definition_from_id(id)
        with_standard_id(id) do |x, y|
          return dimension_scopes[x].try(:dimension_definition) if !y
          return sub_cubes_hash[x].find_metric(y) if sub_cubes_hash[x]
          dimension_scopes.find_level(id).try(:level_definition)
        end
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

      private

      def map_reduce_sub_cubes
        if sub_cubes_hash.length == 1
          yield sub_cubes.first
        else
          arr = sub_cubes_hash.map do |sub_cube_name, sub_cube|
            [sub_cube_name, yield(sub_cube)]
          end
          Hash[arr]
        end
      end

    end
  end
end
