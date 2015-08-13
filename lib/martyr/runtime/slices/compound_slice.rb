module Martyr
  module Runtime
    class CompoundSlice

      attr_accessor :mart, :slices

      def initialize(mart)
        @mart = mart
        @slices = {}
      end

      # Variant 1 - full slice as one hash:
      #   slice(metric: :amount, artist: {with: 'AC/DC'}, genre: {with: 'Rock'}, quantity: {with: '>0'})
      #
      # Variant 2 - on one dimension or metric
      #   slice(:artist, with: 'AC/DC')
      #
      def slice(*several_variants)
        if several_variants.length == 1 and several_variants.is_a?(Hash)
          compound_slice_hash = several_variants.first.stringify_keys.except('metric')
          compound_slice_hash.each do |slice_on, *slice_definition|
            set_one_slice(slice_on, *slice_definition)
          end
        elsif several_variants.is_a? Array
          slice_on, *slice_definition = several_variants
          set_one_slice(slice_on, *slice_definition)
        else
          raise Query::Error.new("Invalid arguments for `slice`: #{several_variants.inspect}")
        end
      end

      # @param scopeable [#update_scope]
      def apply_on_data(scopeable)
        slices.values.each {|slice| slice.apply_on_data(scopeable)}
      end

      # def apply_in_memory(scopeable)
      #   slices.values.each {|slice| slice.apply_in_memory(scopeable)}
      # end

      private

      def set_one_slice(slice_on, **slice_definition)
        slice_on_object = mart.dimension_definitions[slice_on] || mart.metric_definitions[slice_on]
        raise Query::Error.new("Could not find `#{slice_on}` to apply slice on") unless slice_on_object.present?
        @slices[slice_on] = slice_on_object.build_slice(**slice_definition)
      end

    end
  end
end