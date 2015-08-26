module Martyr
  module Runtime
    class Element

      attr_reader :sub_cube, :fact

      def initialize(sub_cube, fact)
        @sub_cube = sub_cube
        @fact = fact
      end

      def inspect
        "#<Martyr::Runtime::Element cube: '#{sub_cube.cube}, data: #{level_hash.inspect}'>"
      end

      def level_hash
        arr = sub_cube.levels.map do |level|
          [level.id, fetch(level)]
        end
        Hash[arr]
      end

      def fetch(*several_variants)
        level = sub_cube.find_level(*several_variants)
        common_denominator = level.common_denominator_with_cube
        common_denominator.recursive_value_lookup fact.fetch(common_denominator.fact_alias), level: level
      end

      def fetch_without_loading(*several_variants)
        level = sub_cube.find_level(*several_variants)
        if level.loaded?
          fetch(*several_variants)
        else
          '?'
        end
      end

    end
  end
end