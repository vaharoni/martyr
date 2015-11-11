module Martyr
  module Runtime

    # This is a service object that allows locating an element given element coordinates and "locate instructions".
    # It is structured to allow locating elements even in the absence of a real element to "start from".

    # A locator deals with real elements - meaning belonging to one cube.

    class ElementLocator
      include ActiveModel::Model
      include Martyr::Translations

      # @attribute metrics [Array<BaseMetric>] the metrics that should be rolled up on the located element
      # @attribute memory_slice [MemorySlice] the current memory slice. Sent to FactIndexer and used to build
      #   Coordinate objects.
      # @attribute fact_indexer [#dimension_bus, #get_element, #cube_name]
      # @attribute restrict_level_ids [Array<String>] level IDs that are supported by the cube this locator belongs to.
      attr_accessor :metrics, :memory_slice, :fact_indexer, :restrict_level_ids

      delegate :dimension_bus, :cube_name, to: :fact_indexer
      delegate :definition_from_id, to: :dimension_bus

      # @param level_ids [Array<String>] the granularity at which the elements need to be fetched
      # @return [Array<Element>]
      def all(level_ids)
        fact_indexer.elements_by(memory_slice, level_ids).map {|element| finalize_element(element)}
      end

      # Get an element based on coordinates.
      # If the coordinates contain an unsupported level, it returns nil.
      # @param grain_hash [Hash] see Coordinates. We do not need Coordinates here so we prefer to allow sending in a
      #   Hash.
      # @param exclude_metric_id [nil, String, Array<String>] @see #finalize_elements
      def get(grain_hash, exclude_metric_id: nil, memory_slice: nil)
        memory_slice ||= self.memory_slice
        throw(:empty_element) if restrict_level_ids.present? and (grain_hash.keys - restrict_level_ids).present?
        elm = fact_indexer.get_element(memory_slice, grain_hash)
        throw(:empty_element) unless elm
        finalize_element(elm, exclude_metric_id: exclude_metric_id)
      end

      # Get an element based on existing coordinates hash AND changes instructions sent to #locate
      # @param grain_hash [Hash] base coordinates that are to be manipulated.
      # @param *several_variants
      # Variant 1:
      #   level_id [String] level ID to slice
      #   with [String] value at level
      # Variant 2:
      #   slice_hash [Hash] level IDs and their values to slice
      # @option reset [String, Array<String>] level ids to remove from coordinates
      # @option standardizer [MetricIdStandardizer]
      # @option exclude_metric_id [String, Array<String>] @see finalize_element
      #
      # @examples
      #   locate(coords, 'customers.country', with: 'USA', reset: '')
      def locate(grain_hash, *several_variants)
        slice_hash, reset_arr, options = sanitize_args_for_locate(*several_variants)
        dimensions_slice_hash, metrics_slice_hash = separate_dimensions_and_metrics(slice_hash)
        new_memory_slice = metrics_slice_hash.present? ? memory_slice.dup_internals.slice_hash(metrics_slice_hash) : memory_slice
        new_coords = coordinates_from_grain_hash(grain_hash, memory_slice: new_memory_slice).locate(dimensions_slice_hash, reset: reset_arr)
        get(new_coords.grain_hash, memory_slice: new_memory_slice, **options)
      end

      private

      # @param grain_hash [Hash]
      # @return [Coordinates]
      def coordinates_from_grain_hash(grain_hash, memory_slice: nil)
        memory_slice ||= self.memory_slice
        Coordinates.new(grain_hash, memory_slice.to_hash)
      end

      # @param element [Hash] element that does not have metrics rolled up and whose element_locator is missing
      # @return [Element] fully initialized
      def finalize_element(element, exclude_metric_id: nil)
        exclude_metric_id = Array.wrap(exclude_metric_id)
        element.element_locator = self
        element.rollup *metrics.reject{|m| exclude_metric_id.include? m.id.to_s }
        element
      end

      def sanitize_args_for_locate(*several_variants)
        if several_variants.length == 2
          slice_definition, reset_arr, options = extract_options_for_locate(several_variants[1])
          slice_hash = {several_variants[0] => slice_definition}
        elsif several_variants.length == 1 and several_variants.first.is_a?(Hash)
          slice_hash, reset_arr, options = extract_options_for_locate(several_variants.first)
        else
          raise ArgumentError.new("wrong number of arguments #{several_variants.length} for (1..2)")
        end
        standardizer = options.delete(:standardizer) || MetricIdStandardizer.new

        validate_no_metrics standardizer.standardize(reset_arr)

        [standardizer.standardize(slice_hash), standardizer.standardize(reset_arr), options]
      end

      def extract_options_for_locate(hash)
        option_keys = [:standardizer, :exclude_metric_id]
        hash_dup = hash.dup

        options = hash_dup.slice(*option_keys)
        reset = hash_dup.delete(:reset) || hash_dup.delete('reset')
        slice = hash_dup.except!(*option_keys)
        [slice, Array.wrap(reset), options]
      end

      # @param hash [Hash] of keys and set instructions
      # @return [Hash, Hash] first hash is dimensions, second is metrics
      def separate_dimensions_and_metrics(hash)
        dimension_keys = hash.keys.select{|id| definition_from_id(first_element_from_id(id)).respond_to?(:dimension)}
        [hash.slice(*dimension_keys), hash.except(*dimension_keys)]
      end

      # @param ids_array [Array] array of fully qualified IDs that contain either metrics or dimensions
      def validate_no_metrics(ids_array)
        ids_array.each do |id|
          raise Query::Error.new('Can only reset on dimensions') unless
            definition_from_id(first_element_from_id(id)).respond_to?(:dimension?)
        end
      end

    end
  end
end
