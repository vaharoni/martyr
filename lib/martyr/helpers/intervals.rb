# Mini and naive library for handling interval overlaps.
# Used predominantly for compounding metric slices.
module Martyr
  class IntervalSet
    attr_reader :set

    def initialize(**options)
      @set = []
      add(**options) if options.present?
    end

    def null?
      set.empty?
    end

    def continuous?
      set.length == 1
    end

    def add(from: -Float::INFINITY, to: Float::INFINITY)
      new_interval = Interval.new(from, to)
      new_interval_set = []
      @set.each do |old_interval|
        if old_interval.touch?(new_interval)
          new_interval = new_interval.union(old_interval)
        else
          new_interval_set << old_interval
        end
      end
      set_interval_set new_interval_set + [new_interval]
    end

    # @param other [IntervalSet]
    def intersect(other)
      new_interval_set = []
      other.set.each do |other_interval|
        new_interval_set += set.select{|x| x.overlap?(other_interval)}.map{|x| x.intersect(other_interval)}
      end
      set_interval_set new_interval_set
    end

    def set_interval_set(set)
      @set = set.sort_by{|interval| interval.from.x.to_f}
      self
    end

    # @return [Array<Numeric>] array of holes - these are open edges that touch each other
    # @note self will be amended to have the holes filled
    def extract_and_fill_holes
      holes = []
      last_edge = nil
      set.each do |interval|
        holes << last_edge if interval.from.open? and interval.from.x == last_edge
        last_edge = interval.to.x if interval.to.open?
      end

      # Fill in the holes
      holes.each do |hole|
        add from: [hole], to: [hole]
      end

      holes
    end

    # @return [Array<>]
    def extract_and_remove_points
      points = @set.select(&:point?).map{|interval| interval.from.x}
      @set.reject!(&:point?)
      points
    end

    # @return [nil, PointInterval]
    def upper_bound
      return nil if null?
      upper_point = set.last.to
      upper_point.infinity? ? nil : upper_point
    end

    # @return [PointInterval]
    def lower_bound
      return nil if null?
      upper_point = set.first.from
      upper_point.infinity? ? nil : upper_point
    end
  end

  # The convention for a basic interval is as follows:
  #   Array value - means including that point
  #   Integer value - means not including that point
  #
  #   Example:
  #     Interval.new [5], 6 - legal
  #     Interval.new [5], [5] - legal
  #     Interval.new [5], 5 - illegal
  class Interval
    attr_reader :from, :to

    def initialize(from, to)
      @from = PointInterval.new(Array.wrap(from).first, from.is_a?(Array), :right)
      @to = PointInterval.new(Array.wrap(to).first, to.is_a?(Array), :left)
      raise Martyr::Error.new('from cannot be bigger than to') if @from.outside?(@to) or @from.equal_but_empty?(@to)
    end

    def point?
      from.closed? and to.closed? and from.x == to.x
    end

    def overlap?(other)
      doesnt_overlap = (to.outside?(other.from) or to.equal_but_empty?(other.from) or from.outside?(other.to) or from.equal_but_empty?(other.to))
      !doesnt_overlap
    end

    def touch?(other)
      return true if overlap?(other)
      return true if to.equal_and_mergeable?(other.from) or from.equal_and_mergeable?(other.to)
      false
    end

    def intersect(other)
      return nil unless overlap?(other)
      self.class.new from.max_with(other.from).to_param, to.min_with(other.to).to_param
    end

    def union(other)
      return nil unless touch?(other)
      self.class.new from.min_with(other.from).to_param, to.max_with(other.to).to_param
    end
  end

  # This represents a starting point and a direction (:left or :right), together with whether the interval includes
  # or excludes the point.
  class PointInterval
    attr_reader :x, :direction

    def initialize(x, closed, direction)
      @x = x
      @closed = closed
      @direction = direction.to_sym
      raise 'direction must be either left or right' unless [:left, :right].include?(@direction)
    end

    def to_param
      closed? ? Array.wrap(x) : x
    end

    def infinity?
      x == Float::INFINITY or x == -Float::INFINITY
    end

    def open?
      !@closed
    end

    def closed?
      !!@closed
    end

    def right?
      direction == :right
    end

    def left?
      direction == :left
    end

    def equal_and_mergeable?(other)
      return false if x != other.x
      return false if open? and other.open?
      true
    end

    def equal_but_empty?(other)
      return false if x != other.x
      return false if closed? and other.closed?
      true
    end

    def inside?(other)
      raise 'other is pointing to the same direction' if direction == other.direction
      if other.right? and other.closed?
        x >= other.x
      elsif other.right? and other.open?
        x > other.x
      elsif other.left? and other.closed?
        x <= other.x
      elsif other.left? and other.open?
        x < other.x
      end
    end

    def outside?(other)
      raise 'other is pointing to the same direction' if direction == other.direction
      if other.right? and other.closed?
        x.to_f < other.x.to_f
      elsif other.right? and other.open?
        x.to_f <= other.x.to_f
      elsif other.left? and other.closed?
        x.to_f > other.x.to_f
      elsif other.left? and other.open?
        x.to_f >= other.x.to_f
      end
    end

    def max_with(other)
      raise 'other is pointing to a different direction' unless direction == other.direction
      if x == other.x
        return [self, other].select(&:closed?).first || self if left?
        return [self, other].select(&:open?).first || self if right?
      end
      [self, other].sort_by{|p| p.x.to_f}.last
    end

    def min_with(other)
      raise 'other is pointing to a different direction' unless direction == other.direction
      if x == other.x
        return [self, other].select(&:open?).first || self if left?
        return [self, other].select(&:closed?).first || self if right?
      end
      [self, other].sort_by{|p| p.x.to_f}.first
    end
  end
end
