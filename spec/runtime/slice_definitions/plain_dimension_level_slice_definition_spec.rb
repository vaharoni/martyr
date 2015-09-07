require 'spec_helper'

describe Martyr::PlainDimensionLevelSliceDefinition do
  let(:subject) { Martyr::PlainDimensionLevelSliceDefinition }

  describe 'creation' do
    it 'keeps with if both with and without are present and different' do
      x = subject.new(with: 5, without: 6)
      expect(x.with).to eq([5])
      expect(x.without).to eq([])
    end

    it 'sets null if both with and without are present and same' do
      x = subject.new(with: 5, without: 5)
      expect(x.null?).to eq(true)
    end

    it 'sets null if both with and without are missing' do
      x = subject.new
      expect(x.null?).to eq(true)
    end

    it 'treats with and without arrays correctly' do
      x = subject.new(with: [1,2,3], without: 2)
      expect(x.with).to eq([1,3])
      expect(x.without).to eq([])
    end

    it 'keeps the active operator if only one is present' do
      x = subject.new(with: [1,2,3])
      expect(x.with).to eq([1,2,3])
      expect(x.without).to eq([])
    end

    it 'keeps the active operator if only one is present' do
      x = subject.new(without: [1,2,3])
      expect(x.without).to eq([1,2,3])
      expect(x.with).to eq([])
    end
  end

  describe 'merge' do
    it 'handles correctly merging of with when there is no overlap' do
      x = subject.new(with: 1)
      y = subject.new(with: 2)
      z = x.merge(y)
      expect(z.with).to eq([])
      expect(z.without).to eq([])
      expect(z.null?).to eq(true)
    end

    it 'handles correctly merging of with when overlaps exist' do
      x = subject.new(with: [1, 2])
      y = subject.new(with: [2, 3])
      z = x.merge(y)
      expect(z.with).to eq([2])
      expect(z.without).to eq([])
    end

    it 'handles correctly merging of without' do
      x = subject.new(without: 1)
      y = subject.new(without: 2)
      z = x.merge(y)
      expect(z.without).to eq([1,2])
      expect(z.with).to eq([])
    end

    it 'handles correctly merging of without when overlap exists' do
      x = subject.new(without: [1, 2])
      y = subject.new(without: [2, 3])
      z = x.merge(y)
      expect(z.without).to eq([1, 2, 3])
      expect(z.with).to eq([])
    end

    it 'handles correctly merging of with and without' do
      x = subject.new(with: [1, 2, 3])
      y = subject.new(without: 7)
      z = x.merge(y)
      expect(z.with).to eq([1, 2, 3])
      expect(z.without).to eq([])
    end

    it 'handles correctly merging of with and without when overlap exists' do
      x = subject.new(with: [1, 2, 3])
      y = subject.new(without: 2)
      z = x.merge(y)
      expect(z.with).to eq([1, 3])
      expect(z.without).to eq([])
    end
  end

end
