module Martyr
  module LevelCollection
    extend ActiveSupport::Concern

    include ActiveModel::Model
    include Martyr::Registrable

    included do
      attr_accessor :dimension
      delegate :dimension_definition, to: :dimension
      delegate :name, to: :dimension, prefix: true
      alias_method :name, :dimension_name             # Allows using #register for LevelCollection
      alias_method :has_level?, :has_key?
      alias_method :find_level, :find_or_error
      alias_method :level_names, :keys
      alias_method :level_objects, :values
    end

    # @param level_name [String, Symbol]
    # @return [Integer]
    def level_index(level_name)
      to_a.index { |name, _object| name.to_s == level_name.to_s }
    end

    def lowest_level
      values.max_by(&:to_i)
    end

  end
end