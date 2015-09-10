module Martyr
  module Runtime
    class VirtualElement

      attr_reader :grain_hash, :locators, :real_elements
      delegate :inspect, to: :to_hash

      def to_hash
        real_elements.inject(grain_hash) {|h, element| h.merge element.to_hash}
      end

      def initialize(grain_hash, locators, real_elements = nil)
        @grain_hash = grain_hash
        @locators = locators
        @real_elements = real_elements || locators.map {|locator| locator.get(grain_hash)}.compact
      end

      def null?
        real_elements.empty?
      end

      def facts(cube_name = nil)
        facts = Hash[real_elements.map {|x| [x.cube_name, x.facts]}]
        cube_name ? facts[cube_name] : facts
      end

      def fetch(key)
        send(:[], key)
      end

      def [](key)
        grain_hash[key] || real_elements.find{|elm| elm[key]}.try(:[], key)
      end

      def locate(*args)
        new_real_elements = locators.map do |locator|
          locator.locate(grain_hash, *args)
        end.compact
        throw(:empty_element) unless new_real_elements.present?
        VirtualElement.new(new_real_elements.first.grain_hash, locators, new_real_elements)
      end

    end
  end
end
