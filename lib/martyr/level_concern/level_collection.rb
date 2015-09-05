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

    # @return [BaseLevelDefinition]
    def level_above(level_name)
      above_index = level_index(level_name) - 1
      return nil if above_index < 0
      values[above_index]
    end

    def level_below(level_name)
      below_index = level_index(level_name) + 1
      values[below_index]
    end

    # @param level_name [String, Symbol]
    # @return [Array<Martyr::Level>] the first level of type `query` below the provided level
    def query_level_below(level_name)
      level_objects[level_index(level_name) + 1..-1].find{|level| level.query?}
    end

    # @param level_name [String, Symbol]
    # @return [Array<Martyr::Level>] the provided level and all the levels above it
    def level_and_above(level_name)
      level_objects[0..level_index(level_name)]
    end

    # @param level_name [String, Symbol]
    # @return [Array<Martyr::Level>] the provided level and all the levels below it
    def level_and_below(level_name)
      level_objects[level_index(level_name)..-1]
    end

    def lowest_level
      values.max_by(&:to_i)
    end

  end
end