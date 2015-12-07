module Martyr
  class Sorter

    def self.default_for_query(label_field)
      ->(record) { record.send(label_field) }
    end

    def self.identity
      ->(value) { value }
    end

    def self.args_to_hash(arg)
      arg.is_a?(Hash) ? arg : Hash[Array.wrap(arg).map{|x| [x, :asc]}]
    end

    def initialize(args)
      @order_hash = self.class.args_to_hash(args)
      @definition_arr = []
      @order_hash.keys.each do |key|
        @definition_arr << yield(key)
      end
    end

    def sort(elements)
      return elements unless @definition_arr.present?
      uniq_values = extract_uniq_values(elements)
      lookups = build_sort_order_lookup(uniq_values)

      elements.sort_by do |element|
        @definition_arr.each_with_index.map{|definition, i| lookups[i][extract_value_from_definition(element, definition)] }
      end
    end

    private

    def extract_value_from_definition(element, definition)
      definition.is_a?(Schema::QueryLevelDefinition) ? element.record_for(definition.id) : element.fetch(definition.id)
    end

    def direction_at(index)
      @order_hash.values[index]
    end

    def sorter_proc_at(index)
      direction = direction_at(index)
      return direction if direction.respond_to?(:call)
      @definition_arr[index].sort
    end

    # @param elements [Array<Element>] elements to be sorted
    # @return [Array<Array>] each index of the master array corresponds to one level of nested sorting.
    #   E.g., if the user asked to sort by ['genres.name', 'media_types.name'], the result will be an array where
    #     index 0 contains all unique values of the genres extracted from the elements, and index 0 contains all
    #     unique values of the media types extracted from the elements.
    #
    def extract_uniq_values(elements)
      arr = []
      @definition_arr.each_with_index do |definition, i|
        elements.each do |element|
          value = extract_value_from_definition(element, definition)
          arr[i] ||= {}
          arr[i][value] = true
        end
      end
      arr.map!(&:keys)
    end

    # @param uniq_values [Array<Array>] see return value of #extract_uniq_values
    def build_sort_order_lookup(uniq_values)
      lookups = []
      uniq_values.each_with_index do |uniq_values_arr, i|
        sorted_values = uniq_values_arr.sort_by { |x| sorter_proc_at(i).call(x) }
        sorted_values.reverse! if direction_at(i).to_s == 'desc'
        lookups << Hash[sorted_values.each_with_index.map{|value, i| [value, i]}]
      end
      lookups
    end
  end
end
