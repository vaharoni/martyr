module Martyr
  module Schema
    class BaseLevelDefinition
      include ActiveModel::Model
      include Martyr::Level

      # @attribute fact_key [String] the field in the fact where the degenerate attribute resides. E.g.:
      #   degenerate_level :country, fact_key: 'invoices.country'
      #
      # @attribute fact_alias [String] the alias to give in the `AS` part of the SQL fact statement.
      #
      attr_accessor :name, :fact_key, :fact_alias

      delegate :dimension_name, :dimension_definition, to: :collection
      alias_method :slice_id, :dimension_name
      delegate :build_data_slice, :build_memory_slice, to: :dimension_definition

      # This allows to ask any Martyr::Level for #level_definition
      def level_definition
        self
      end

      def dimension_definition
        collection.dimension
      end

      def supported?
        false
      end
    end
  end
end
