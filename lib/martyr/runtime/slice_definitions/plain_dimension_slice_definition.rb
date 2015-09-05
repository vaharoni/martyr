module Martyr
  class PlainDimensionSliceDefinition < BaseSliceDefinition

    attr_accessor :with, :without

    def to_hash
      hash = {}
      hash.merge! with: with if with.present?
      hash.merge! without: without if without.present?
      hash
    end

    def merge(other)
      merged_with = with.present? && other.with.present? ? with & other.with : with + other.with
      self.class.new(with: merged_with, without: without + other.without)
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

