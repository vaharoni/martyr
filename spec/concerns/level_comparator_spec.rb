require 'spec_helper'

describe Martyr::LevelComparator do
  let(:subject) { Class.new.include(Martyr::LevelComparator).new }

  describe 'more_detailed_level' do
    let(:cube) { MartyrSpec::DegeneratesAndBottomLevels }
    let(:country_level) { cube.dimension_definitions.find_level_definition('customers.country') }
    let(:state_level) { cube.dimension_definitions.find_level_definition('customers.state') }
    let(:city_level) { cube.dimension_definitions.find_level_definition('customers.city') }
    let(:last_name_level) { cube.dimension_definitions.find_level_definition('customers.last_name') }
    let(:last_name_level_association) { cube.dimension_associations.find_level_association('customers.last_name') }

    it 'returns nil when both are nil' do
      expect(subject.more_detailed_level(nil, nil)).to eq(nil)
    end

    it 'returns level1 when level2 is nil' do
      expect(subject.more_detailed_level(city_level, nil)).to eq(city_level)
    end

    it 'returns level1 when it is equal to level2' do
      expect(subject.more_detailed_level(last_name_level, last_name_level_association)).to eq(last_name_level)
      expect(subject.more_detailed_level(last_name_level_association, last_name_level)).to eq(last_name_level_association)
    end

    it 'returns level1 when it is lower than level2' do
      expect(subject.more_detailed_level(city_level, country_level)).to eq(city_level)
    end

    it 'returns level2 when level1 is nil' do
      expect(subject.more_detailed_level(nil, city_level)).to eq(city_level)
    end

    it 'returns level2 when it is lower than level1' do
      expect(subject.more_detailed_level(city_level, last_name_level)).to eq(last_name_level)
      expect(subject.more_detailed_level(city_level, last_name_level_association)).to eq(last_name_level_association)
    end
  end

  describe 'find_common_denominator_level' do
    context 'does not prefer query or ' do
      let(:cube) { MartyrSpec::DegeneratesAndHighLevels }
      let(:scopes) { cube.build_dimension_scopes('invoices') }
      let(:level_associations) { cube.dimension_associations.find_dimension_association('invoices').level_objects }
      let(:city_level) { scopes.find_level('invoices.city') }
      let(:invoice_level) { scopes.find_level('invoices.invoice') }
      let(:invoice_line_level) { scopes.find_level('invoices.invoice_line') }

      it 'returns the same level if it is supported' do
        expect(subject.find_common_denominator_level(invoice_level.level, [invoice_level])).to eq(invoice_level.level)
      end

      it 'returns a lower supported level if it is not directly supported' do
        expect(subject.find_common_denominator_level(city_level.level, [invoice_level])).to eq(invoice_level.level)
        expect(subject.find_common_denominator_level(city_level.level, level_associations)).to eq(invoice_level.level)
      end

      it 'returns nil if no level is supported below' do
        expect(subject.find_common_denominator_level(invoice_line_level.level, level_associations)).to eq(nil)
      end
    end

    context 'prefers query and query level exists' do
      let(:cube) { MartyrSpec::DegeneratesAndHoleAndLowLevel }
      let(:customers_scopes) { cube.build_dimension_scopes('customers') }
      let(:customers_level_associations) { cube.dimension_associations.find_dimension_association('customers').level_objects }
      let(:customers_country_level) { customers_scopes.find_level('customers.country') }
      let(:customers_state_level) { customers_scopes.find_level('customers.state') }
      let(:customers_city_level) { customers_scopes.find_level('customers.city') }
      let(:customers_last_name_level) { customers_scopes.find_level('customers.last_name') }

      let(:invoices_scope) { cube.build_dimension_scopes('invoices') }
      let(:invoices_level_associations) { cube.dimension_associations.find_dimension_association('invoices').level_objects }
      let(:invoices_country_level) { invoices_scope.find_level('invoices.country') }
      let(:invoices_state_level) { invoices_scope.find_level('invoices.state') }
      let(:invoices_city_level) { invoices_scope.find_level('invoices.city') }
      let(:invoices_invoice_level) { invoices_scope.find_level('invoices.invoice') }
      let(:invoices_invoice_line_level) { invoices_scope.find_level('invoices.invoice_line') }

      it 'returns query even if degenerate supported' do
        expect(subject.find_common_denominator_level(customers_country_level.level, customers_level_associations, prefer_query: true)).
          to eq(customers_last_name_level.level)
        expect(subject.find_common_denominator_level(customers_state_level.level, customers_level_associations, prefer_query: true)).
          to eq(customers_last_name_level.level)
      end

      it 'returns query when degenerate not supported' do
        expect(subject.find_common_denominator_level(customers_city_level.level, customers_level_associations, prefer_query: true)).
          to eq(customers_last_name_level.level)
        expect(subject.find_common_denominator_level(invoices_state_level.level, invoices_level_associations, prefer_query: true)).
          to eq(invoices_invoice_level.level)
      end

      it 'returns query when query is supported' do
        expect(subject.find_common_denominator_level(customers_last_name_level.level, customers_level_associations, prefer_query: true)).
          to eq(customers_last_name_level.level)
      end
    end

    context 'prefers query and query level does not exist' do
      let(:cube) { MartyrSpec::DegeneratesAndNoQueryLevel }
      let(:customers_scopes) { cube.build_dimension_scopes('customers') }
      let(:customers_level_associations) { cube.dimension_associations.find_dimension_association('customers').level_objects }
      let(:customers_country_level) { customers_scopes.find_level('customers.country') }
      let(:customers_state_level) { customers_scopes.find_level('customers.state') }
      let(:customers_city_level) { customers_scopes.find_level('customers.city') }
      let(:customers_last_name_level) { customers_scopes.find_level('customers.last_name') }

      it 'returns degenerate correctly' do
        expect(subject.find_common_denominator_level(customers_country_level.level, customers_level_associations, prefer_query: true)).
          to eq(customers_state_level.level)
      end

    end
  end
end
