require 'spec_helper'

describe Martyr::LevelComparator do
  let(:subject) { Class.new.include(Martyr::LevelComparator).new }

  describe 'more_detailed_level' do
    before do
      cube = MartyrSpec::DegeneratesAndBottomLevels
      @l1 = cube.find_dimension_definition(:customers).find_level(:country)
      @l2 = cube.find_dimension_definition(:customers).find_level(:state)
      @l3 = cube.find_dimension_definition(:customers).find_level(:city)
      @l4 = cube.find_dimension_definition(:customers).find_level(:last_name)
      @l4_assoc = cube.find_dimension(:customers).find_level(:last_name)
    end

    it 'returns nil when both are nil' do
      expect(subject.more_detailed_level(nil, nil)).to eq(nil)
    end

    it 'returns level1 when level2 is nil' do
      expect(subject.more_detailed_level(@l3, nil)).to eq(@l3)
    end

    it 'returns level1 when it is equal to level2' do
      expect(subject.more_detailed_level(@l4, @l4_assoc)).to eq(@l4)
      expect(subject.more_detailed_level(@l4_assoc, @l4)).to eq(@l4_assoc)
    end

    it 'returns level1 when it is lower than level2' do
      expect(subject.more_detailed_level(@l3, @l1)).to eq(@l3)
    end

    it 'returns level2 when level1 is nil' do
      expect(subject.more_detailed_level(nil, @l3)).to eq(@l3)
    end

    it 'returns level2 when it is lower than level1' do
      expect(subject.more_detailed_level(@l3, @l4)).to eq(@l4)
      expect(subject.more_detailed_level(@l3, @l4_assoc)).to eq(@l4_assoc)
    end
  end

  describe 'find_common_denominator_level' do
    before do
      cube = MartyrSpec::DegeneratesAndHighLevels
      @scopes = cube.build_dimension_scopes
      @level_city = @scopes.find_level(:invoices, :city)
      @level_invoice = @scopes.find_level(:invoices, :invoice)
      @level_invoice_line = @scopes.find_level(:invoices, :invoice_line)
    end

    it 'returns the same level if it is supported' do
      expect(subject.find_common_denominator_level(@level_invoice, [@level_invoice])).to eq(@level_invoice)
    end

    it 'returns a lower supported level if it is not directly supported' do
      expect(subject.find_common_denominator_level(@level_city, [@level_invoice])).to eq(@level_invoice)
      expect(subject.find_common_denominator_level(@level_city, @dimension.levels)).to eq(@dimension.find_level(:invoice))
    end

    it 'returns nil if no level is supported below' do
      expect(subject.find_common_denominator_level(@level_invoice_line, @dimension.levels)).to eq(nil)
    end
  end
end
