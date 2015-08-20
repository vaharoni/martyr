require 'spec_helper'

describe Martyr::Schema::LevelDefinitionCollection do
  let(:dimension) { Martyr::Schema::DimensionDefinition.new(:dimension) }
  let(:subject) { Martyr::Schema::LevelDefinitionCollection.new(dimension: dimension) }

  describe 'query_level_below' do
    context 'there is a query level' do
      before do
        @l1 = subject.degenerate_level :country
        @l2 = subject.degenerate_level :state
        @l3 = subject.query_level :customer, -> { Customer.all }
        @l4 = subject.query_level :fake_level, -> { Invoice.all }
      end

      it 'fetches the right level' do
        expect(subject.query_level_below(:country)).to eq(@l3)
        expect(subject.query_level_below(:state)).to eq(@l3)
        expect(subject.query_level_below(:customer)).to eq(@l4)
        expect(subject.query_level_below(:fake_level)).to eq(nil)
      end
    end

    context 'there is no query level' do
      before do
        @l1 = subject.degenerate_level :country
        @l2 = subject.degenerate_level :state
      end

      it 'returns nil' do
        expect(subject.query_level_below(:country)).to eq(nil)
        expect(subject.query_level_below(:state)).to eq(nil)
      end
    end
  end
end