module Martyr
  module Schema
    module IsLevelCollection
      extend ActiveSupport::Concern

      include ActiveModel::Model
      include Martyr::Registrable

      included do
        attr_accessor :dimension
        delegate :name, to: :dimension, prefix: true
        alias_method :has_level?, :has_key?
        alias_method :find_level, :find_or_error
        alias_method :level_names, :keys
      end

      def lowest_level
        values.max(&:to_i)
      end

      def level_names_and_i
        map{|level_name, level_object| [level_name, level_object.to_i]}
      end

      # @param level_name [String, Symbol]
      # @return [Integer]
      def level_index(level_name)
        to_a.index{|name, _object| name.to_s == level_name.to_s }
      end

    end
  end
end