module Martyr
  module Runtime
    class Element < HashWithIndifferentAccess
      include Martyr::Translations
      include Martyr::Runtime::ElementCommon

      # @attribute element_locator [ElementLocator] this is added to an element in the process of building it
      attr_accessor :element_locator

      attr_reader :facts
      delegate :cube_name, to: :element_locator
      delegate :grain_level_ids, :grain_hash, to: :@coordinates

      # @param coordinates [Coordinates]
      # @param values_hash [Hash] of the structure level_id => value. Unlike `coordinates.grain_hash`, for query levels the
      #   value is the string value, not the primary key.
      # @param facts [Array<Fact>]
      def initialize(coordinates, values_hash, facts)
        @coordinates = coordinates
        @facts = facts

        merge! values_hash
      end

      # @param key [String] either metric id or level id
      def fetch(key)
        value = super(key)
        value.is_a?(FutureMetric) ? value.value : value
      end
      alias_method :[], :fetch

      def coordinates(*)
        @coordinates.to_hash
      end

      def coordinates_object(*)
        @coordinates
      end

      def locate(*args)
        element_locator.locate(grain_hash, *args)
      end

      # Loads all future values
      def load
        keys.each{|key| fetch(key)}
        self
      end

      def key_for(level_id)
        raise Query::Error.new("Error: `#{level_id}` must be included in the element grain") unless grain_hash.keys.include?(level_id)
        facts.first.fact_key_for(level_id)
      end

      def record_for(level_id)
        raise Query::Error.new("Error: `#{level_id}` must be included in the element grain") unless grain_hash.keys.include?(level_id)
        facts.first.record_for(level_id)
      end

      private

      def method_missing(method, *args, &block)
        fully_qualified_metric_id = find_metric_id(method)
        return fetch(fully_qualified_metric_id) if fully_qualified_metric_id
        super
      end

      # @return [String] the fully qualified metric ID if only one exists
      def find_metric_id(key)
        candidates = metric_ids.select{|metric_id| second_element_from_id(metric_id) == key.to_s}
        return candidates.first if candidates.length == 1
        nil
      end

    end
  end
end
