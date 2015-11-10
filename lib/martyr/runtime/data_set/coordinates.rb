module Martyr
  module Runtime
    class Coordinates
      include ActiveModel::Model
      include Martyr::Translations

      # @attribute coordinates_hash [Hash] with keys of the form:
      #     'dimension_name.level_name'
      #     'cube_name.metric_name'
      #   and values representing the slice

      attr_reader :grain_hash, :memory_slice_hash

      # @param grain_hash [Hash] of the structure level_id => value. For query levels, value is the primary key.
      #   Note that it does not include metrics, and other background restrictions on the slice
      # @param memory_slice_hash [Hash]
      def initialize(grain_hash, memory_slice_hash)
        @grain_hash = grain_hash
        @memory_slice_hash = memory_slice_hash
      end

      # @return [Hash] of coordinates that can get the same element when sent to a QueryContextBuilder#slice
      def to_hash
        memory_slice_hash.merge(grain_coordinates)
      end

      # @return [Array<String>]
      def grain_level_ids
        grain_hash.keys
      end

      # @return [Hash] of the grain in a format that is understood by QueryContextBuilder#slice
      def grain_coordinates
        grain_hash.inject({}) { |h, (level_id, level_value)| h[level_id] = {with: level_value}; h }
      end

      def dup
        super.dup_internals
      end

      def reset(*args)
        dup.reset!(*args)
      end

      def set(*args)
        dup.set!(*args)
      end

      def locate(*args)
        dup.locate!(*args)
      end

      def locate!(slice_hash={}, reset: [])
        reset.each { |reset_on| reset!(reset_on) }
        set!(slice_hash)
        self
      end

      # @param reset_on [String, Array<String>]
      #   The caller must guarantee that only levels and dimensions are sent to #reset!.
      #   Since this object is not hierarchy-aware, the caller must send all levels below the level asked to be reset.
      #
      #   There are two acceptable formats:
      #   'dimension_name.level_name' - to remove a particular level
      #   'dimension_name.*' - to remove a dimension with all its levels
      #
      def reset!(reset_on)
        if second_element_from_id(reset_on) == '*'
          reset_dimension first_element_from_id(reset_on)
        else
          grain_hash.except!(reset_on)
        end
        self
      end

      # @param slice_hash [Hash] of one of the formats:
      #   'dimension_name.level_name' => {with: 'value'}
      #   'dimension_name.level_name' => {'with' => 'value'}
      #
      #   The caller must guarantee that only levels and dimensions are sent.
      #
      def set!(slice_hash)
        slice_hash.group_by { |k, _| first_element_from_id(k) }.each do |dimension_name, slice_hashes_arr|
          reset_dimension dimension_name
          slice_hashes_arr.each do |slice_on, slice_definition|
            raise Query::Error.new('incorrect usage of locate') unless slice_definition.stringify_keys.keys == ['with']
            grain_hash.merge! slice_on => slice_definition.stringify_keys['with']
          end
        end
        self
      end

      protected

      def dup_internals
        @grain_hash = @grain_hash.dup
        self
      end

      private

      def reset_dimension(dimension_name)
        grain_hash.reject! { |k, _| first_element_from_id(k) == dimension_name }
      end

    end
  end
end
