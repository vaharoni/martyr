module Martyr
  class PlainDimensionSliceDefinition < BaseSliceDefinition

    attr_accessor :with, :without

    def to_hash
      {with: with, without: without}.compact
    end

    private

    def compile_operators
      set_null if with and without
      set_null unless with or without
    end

  end
end

