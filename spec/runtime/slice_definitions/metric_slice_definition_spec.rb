require 'spec_helper'

describe Martyr::MetricSliceDefinition do
  let(:subject) { Martyr::MetricSliceDefinition }

  describe 'creation' do
    it 'handles eq and not together' do
      x = subject.new eq: 1, not: 1
      expect(x.null?).to eq(true)
    end

    it 'handles gt and gte together when gte is bigger' do
      x = subject.new(gt: 1, gte: 2)
      expect(x.gte).to eq(2)
      expect(x.gt).to eq(nil)
    end

    it 'handles gt and gte together when gte is the same' do
      x = subject.new(gt: 1, gte: 1)
      expect(x.gt).to eq(1)
      expect(x.gte).to eq(nil)
    end

    it 'handles gt and gte together when gte is smaller' do
      x = subject.new(gt: 2, gte: 1)
      expect(x.gt).to eq(2)
      expect(x.gte).to eq(nil)
    end

    it 'handles lt and lte together when lte is smaller' do
      x = subject.new(lt: 2, lte: 1)
      expect(x.lte).to eq(1)
      expect(x.lt).to eq(nil)
    end

    it 'handles lt and lte together when lte is the same' do
      x = subject.new(lt: 2, lte: 2)
      expect(x.lt).to eq(2)
      expect(x.lte).to eq(nil)
    end

    it 'handles lt and lte together when lte is bigger' do
      x = subject.new(lt: 1, lte: 2)
      expect(x.lt).to eq(1)
      expect(x.lte).to eq(nil)
    end

    it 'handles non overlapping ranges' do
      x = subject.new(lt: 1, gt: 2)
      expect(x.null?).to eq(true)
    end

    it 'handles non overlapping ranges on the dot' do
      x = subject.new(lt: 2, gt: 2)
      expect(x.null?).to eq(true)

      x = subject.new(lte: 2, gt: 2)
      expect(x.null?).to eq(true)

      x = subject.new(lt: 2, gte: 2)
      expect(x.null?).to eq(true)
    end

    it 'handles overlapping ranges' do
      x = subject.new(lt: 3, gte: 1)
      expect(x.lt).to eq(3)
      expect(x.gte).to eq(1)
    end

    it 'handles overlapping ranges on the dot' do
      x = subject.new(lte: 2, gte: 2)
      expect(x.lte).to eq(nil)
      expect(x.gte).to eq(nil)
      expect(x.eq).to eq(2)
    end

    it 'handles eq together with an lte range outside' do
      x = subject.new(eq: 2, lte: 1)
      expect(x.null?).to eq(true)
    end

    it 'handles eq together with an gte range outside' do
      x = subject.new(eq: 2, gte: 3)
      expect(x.null?).to eq(true)
    end

    it 'handles eq together with an overlapping range' do
      x = subject.new(eq: 2, gte: 1, lte: 3)
      expect(x.gte).to eq(nil)
      expect(x.lte).to eq(nil)
      expect(x.eq).to eq(2)
    end

    it 'handles not with ranges' do
      x = subject.new(gte: 1, lte: 3, not: 2)
      expect(x.gte).to eq(1)
      expect(x.lte).to eq(3)
      expect(x.not).to eq(2)
    end
  end

  describe 'merge' do
    it 'merges correctly overlapping ranges' do
      x = subject.new(gte: 10, lte: 20)
      y = subject.new(gt: 15, lt: 25)
      z = x.merge(y)
      expect(z.gt).to eq(15)
      expect(z.gte).to eq(nil)
      expect(z.lt).to eq(nil)
      expect(z.lte).to eq(20)
    end

    it 'merges correctly equal eq' do
      x = subject.new(eq: 5)
      y = subject.new(eq: 5)
      z = x.merge(y)
      expect(z.eq).to eq(5)
    end

    it 'merges correctly non-equal eq' do
      x = subject.new(eq: 5)
      y = subject.new(eq: 6)
      z = x.merge(y)
      expect(z.null?).to eq(true)
    end
  end
end