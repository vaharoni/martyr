module Martyr
  class PlainDimensionLevelSliceDefinition < BaseSliceDefinition

    # @attribute level [BaseLevelDefinition]
    attr_accessor :level, :with

    def to_hash
      {level.id => {with: with}}
    end

    def merge(other)
      raise Internal::Error.new('Cannot merge two different levels') unless level.id == other.level.id
      merged_with = with.present? && other.with.present? ? with & other.with : with + other.with
      self.class.new(level: level, with: merged_with)
    end

    private

    def compile_operators
      @with = Array.wrap(@with).uniq
      set_null unless @with.present?
    end

  end
end

