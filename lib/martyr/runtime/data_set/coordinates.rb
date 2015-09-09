module Martyr
  module Runtime
    class Coordinates
      include ActiveModel::Model
      include Martyr::Translations

      attr_accessor :grain_hash, :memory_slice, :dimension_bus
      delegate :definition_from_id, to: :dimension_bus

      def inspect
        to_hash.inspect
      end

      def dup
        self.class.new(grain_hash: grain_hash.dup, memory_slice: memory_slice.dup, dimension_bus: dimension_bus)
      end

      def to_hash
        memory_slice.to_hash.merge!(grain_coordinates)
      end

      def locate(*args)
        dup.locate!(*args)
      end

      # @examples
      #   locate('customers.city', with: 'Dover')
      #   locate('customers.city' => {with: 'Dover'}, 'customers.country' => {with: 'USA'}, 'cube.amount' => {gt: 10}, reset: ['genres.name', 'media_types.*'])
      #   locate('customers.city' => {without: 'Dover'})
      #
      # Note that the address returned DOES NOT contain coordinates of levels that were sliced on, so that the last
      # example above can be handled. The element's coordinates will be safe to use, but the grain of the element won't
      # contain 'customers.city' in neither examples, even though in the first two example it might be convenient to
      # have customers.city in the grain.
      #
      def locate!(slice_hash={}, reset: [])
        reset.each { |reset_on| reset!(reset_on) }
        set!(slice_hash)
        self
      end

      def set!(slice_hash)
        return self unless slice_hash.present?

        slice_hash.group_by { |k, v| first_element_from_id(k) }.each do |cube_or_dimension_name, slice_hashes_arr|
          reset_dimension(cube_or_dimension_name) if definition_from_id(slice_hash.keys.first).respond_to?(:level_object?)
          slice_hashes_arr.each do |slice_on, slice_definition|
            memory_slice.slice(slice_on, slice_definition)
          end
        end
        self
      end

      def reset!(reset_on)
        if second_element_from_id(reset_on) == '*'
          reset_dimension first_element_from_id(reset_on)
        else
          reset_on_object = definition_from_id(reset_on)
          if reset_on_object.respond_to?(:level_object?)
            reset_on_object.level_and_below.map(&:id).each { |level_id| reset_level(level_id) }
          else
            reset_metric(reset_on)
          end
        end
        self
      end

      private

      def grain_coordinates
        grain_hash.inject({}) { |h, (level_id, level_value)| h[level_id] = {with: level_value}; h }
      end

      def reset_dimension(dimension_name)
        grain_hash.reject! { |k, _| first_element_from_id(k) == dimension_name }
        memory_slice.reset_dimension(dimension_name)
      end

      def reset_level(level_id)
        grain_hash.except!(level_id)
        memory_slice.reset_level(level_id)
      end

      def reset_metric(metric_id)
        memory_slice.reset_metric(metric_id)
      end
    end
  end
end
