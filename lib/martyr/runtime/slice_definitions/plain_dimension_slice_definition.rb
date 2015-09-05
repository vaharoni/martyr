module Martyr
  class PlainDimensionSliceDefinition < BaseSliceDefinition

    attr_accessor :with, :without

    def to_hash
      {with: with, without: without}.compact
    end

    def merge(other)
      self.class.new(with: with + other.with, without: without + other.without)
    end

    private

    def compile_operators
      @with = Array.wrap(@with).uniq
      @without = Array.wrap(@without).uniq
      if @with.present? and @without.present?
        @with = @with - @without
        @without = []
        set_null if @with.empty?
      elsif with.blank? and without.blank?
        set_null
      end
    end

  end
end

