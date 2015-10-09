module Martyr
  module Runtime
    class VirtualElementsBuilder

      attr_reader :collections

      def initialize
        @collections = []
      end

      def add(*args)
        @collections << ElementsFromOneSubCube.new(*args)
      end

      def build
        return collections.first.elements if collections.length == 1
        locators = @collections.map(&:to_locator)

        level_values.first.product(*level_values[1..-1]).map do |grain_values|
          grain_arr = levels.each_with_index.map { |level, i| [level, grain_values[i]] }
          elm = VirtualElement.new(Hash[grain_arr], locators)
          elm.null? ? nil : elm
        end.compact
      end

      def levels
        @_levels ||= collections.flat_map(&:levels).uniq
      end

      def level_values
        @_level_values ||= levels.map do |level|
          values_for_level(level)
        end
      end

      def values_for_level(level)
        collections.flat_map { |x| x.values_for_level(level) }.uniq
      end

      def self.values_by_level(elements_arr_of_arr, levels)
        hash = {}
        levels.each do |level|
          hash[level] = []
          elements_arr_of_arr.each do |elements_arr|
            elements_arr.each do |element|
              element[level]
            end
          end
        end
      end

      def self.shared_grain(grains_arr)
        grains_arr.inject(grains_arr.first.keys) { |shared_grain, grain_hash| shared_grain & grain_hash.keys }
      end


      class ElementsFromOneSubCube
        include ActiveModel::Model
        attr_accessor :elements, :cube_name, :memory_slice, :address_resolver

        def default_element
          elements.first
        end

        def grain
          default_element.grain_hash
        end

        def metrics
          default_element.metrics
        end

        def levels
          grain.keys
        end

        def values_for_level(level)
          levels.include?(level) ? elements.map { |x| x[level] }.uniq : []
        end

        def to_locator
          ElementLocator.new cube_name: cube_name, memory_slice: memory_slice, address_resolver: address_resolver,
            metrics: metrics, restrict_levels: levels
        end
      end

    end
  end
end
