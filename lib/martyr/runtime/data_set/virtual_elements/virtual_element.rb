module Martyr
  module Runtime

    # A virtual element is an element that does not really exist, because its grain is comprised of multiple cubes
    # that do not make sense together.
    #
    # It is only useful in the context of relaxing some dimensions in the process of building totals.
    #
    # Example:
    #
    #     Cube 1
    #       genres.name     media_types.name    playlists.name      tracks_count
    #       Rock            CD                  My playlist         10
    #
    #     Cube 2
    #        genres.name    media_types.name    customers.country   units_sold
    #        Rock           CD                  France              95
    #
    #     Virtual elements
    #        genres.name    media_types.name    playlists.name    customers.country       tracks_count    units_sold
    #        Rock           CD                  My playlist
    #

    class VirtualElement

      attr_reader :grain_hash, :locators, :real_elements, :memory_slice
      delegate :inspect, to: :to_hash

      def to_hash
        real_elements.inject(grain_hash) {|h, element| h.merge element.to_hash}
      end

      # @param memory_slice [MemorySlice] cross cubes memory slice
      def initialize(grain_hash, memory_slice, locators, real_elements = nil)
        @grain_hash = grain_hash
        @memory_slice = memory_slice
        @locators = locators
        @real_elements = real_elements || find_real_elements(:get)
      end

      def null?
        real_elements.empty?
      end

      def coordinates(metric_id)
        coordinates_object(metric_id).to_hash
      end

      def coordinates_object(metric_id)
        real_elements.find{|x| x.has_key?(metric_id)}.try(:coordinates_object)
      end

      def facts(cube_name = nil)
        facts = Hash[real_elements.map {|x| [x.cube_name, x.facts]}]
        cube_name ? facts[cube_name] : facts
      end

      def fetch(key)
        send(:[], key)
      end

      def [](key)
        grain_hash[key] || real_elements.find{|elm| elm.has_key?(key)}.try(:[], key)
      end

      def locate(*args)
        new_real_elements = find_real_elements(:locate, *args)
        throw(:empty_element) unless new_real_elements.present?
        VirtualElement.new(new_real_elements.first.grain_hash, memory_slice, locators, new_real_elements)
      end

      def warnings
        arr = real_elements.flat_map do |elm|
          elm.metrics.map{|metric| [metric.id, warning(metric.id)]}
        end
        Hash[arr]
      end

      def warning(metric_id)
        unsupported_keys_in_memory_slice = memory_slice.keys - coordinates(metric_id).keys
        return [] if unsupported_keys_in_memory_slice.blank?
        "Metric `#{metric_id}` does not support slice on: `#{unsupported_keys_in_memory_slice.join('`, `')}`"
      end

      def load
        real_elements.try(:each, &:load)
        self
      end

      private

      # @param method_name [:get, :locate]
      # @param args [Array] args for locate
      def find_real_elements(method_name, *args)
        locators.map do |locator|
          catch(:empty_element) do
            locator.send(method_name, grain_hash, *args)
          end
        end.compact
      end

    end
  end
end
