module Martyr
  module Runtime

    # This is a service object that allows locating an element given element coordinates and "locate instructions".
    # It is structured to allow locating elements even in the absence of a real element to "start from".

    # A locator is associated with real elements - meaning belonging to one cube.

    class ElementLocator
      include ActiveModel::Model
      include Martyr::Translations

      # @attribute metrics [Array<BaseMetric>] the metrics that should be rolled up on the located element
      # @attribute memory_slice [MemorySlice] the current slice memory slice. Used to produce Coordianates.
      # @attribute fact_indexer [#dimension_bud, #get_element] currently a FactIndexer.
      # @attribute restrict_level_ids [Array<String>] level IDs that are supported by the cube this locator is
      attr_accessor :metrics, :memory_slice, :fact_indexer, :restrict_level_ids

      delegate :dimension_bus, to: :fact_indexer
      delegate :definition_from_id, to: :dimension_bus

      # @param level_ids [Array<String>] the granularity at which the elements need to be fetched
      # @return [Array<Element>]
      def all(level_ids)
        fact_indexer.elements_by(memory_slice, level_ids).map {|element| finalize_element(element)}
      end

      # Get an element based on existing coordinates hash
      def get(coordinates, exclude_metric_id: nil)
        elm = fact_indexer.get_element(coordinates)
        return nil unless elm
        finalize_element(elm, exclude_metric_id: exclude_metric_id)
      end

      # Get an element based on existing coordinates hash AND changes instructions sent to #locate
      def locate(coordinates, *several_variants)
        slice_hash, reset_arr, options = sanitize_args_for_locate(*several_variants)
        new_coords = coordinates.locate slice_hash, reset_arr
        return nil if restrict_level_ids.present? and (new_coords.grain_level_ids - restrict_level_ids).present?
        get(new_coords, **options)
      end

      private

      # @param element [Hash] element that does not have metrics rolled up and whose element_locator is missing
      # @return [Element] fully initialized
      def finalize_element(element, exclude_metric_id: nil)
        exclude_metric_id ||= []
        element.rollup *(metrics - exclude_metric_id)
        element.element_locator = self
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

        [validate_ids(standardizer.standardize(slice_hash), :values),
          validate_ids(standardizer.standardize(reset_arr), :to_a), options]
      end

      def extract_options_for_locate(hash)
        option_keys = [:standardizer, :exclude_metric_ids]
        hash_dup = hash.dup

        options = hash_dup.slice(*option_keys)
        reset = hash_dup.delete(:reset) || hash_dup.delete('reset')
        slice = hash_dup.except!(*option_keys)
        [slice, Array.wrap(reset), options]
      end

      # @return [Object] object if all went well
      def validate_ids(object, iterator_method)
        object.send(iterator_method).each do |id|
          raise Query::Error.new('Can only call locate on dimensions') unless
            definition_from_id(first_element_from_id(id)).is_a?(DimensionReference)
        end
        object
      end

    end
  end
end
