require 'spec_helper'

describe 'Dimension Scopes Loading and Tree Traversal' do
  let(:dimension_scopes) { MartyrSpec::DegeneratesAndBottomLevels.all.build.dimension_scopes }
  let(:country_level) { dimension_scopes.find_level('invoices.country') }
  let(:state_level) { dimension_scopes.find_level('invoices.state') }
  let(:city_level) { dimension_scopes.find_level('invoices.city') }
  let(:invoice_level) { dimension_scopes.find_level('invoices.invoice') }
  let(:invoice_line_level) { dimension_scopes.find_level('invoices.invoice_line') }

  describe 'loading without slicing' do
    it 'loads the full level for query level with #all on a non-sliced dimension' do
      expect(invoice_level.all).to eq(Invoice.all.to_a)
    end

    it 'loads the query level below when loading a degenerate level with #all on a non-sliced dimension' do
      expect(state_level.all.compact.sort).to eq(Invoice.all.map(&:billing_state).compact.uniq.sort)
    end
  end

  describe 'slicing and loading same level' do
    it 'returns true for #loaded? and #load and does not run queries if already loaded for query level' do
      invoice_level.slice_with('invoice-1')
      expect(invoice_level).not_to receive(:set_cache)
      expect(invoice_level.loaded?).to eq(true)
      expect(invoice_level.load).to eq(true)
    end

    it 'returns true for #loaded? if query level already loaded for degenerate level' do
      invoice_level.slice_with('invoice-1')
      expect(city_level.loaded?).to eq(true)
    end

    it 'returns the record slice with #all for sliced query level' do
      invoice_level.slice_with('invoice-1')
      expect(invoice_level.all).to eq([Invoice.find(1)])
    end

    it 'returns the record slice with #keys for sliced query level' do
      invoice_level.slice_with('invoice-1')
      expect(invoice_level.keys).to eq([1])
    end

    it 'returns a record with #fetch for sliced query level' do
      invoice_level.slice_with('invoice-1')
      expect(invoice_level.fetch(1)).to eq(Invoice.find(1))
    end

    it 'returns correct values with #all and #keys for degenerate level whose query level is loaded' do
      invoice_level.slice_with('invoice-1')
      expect(city_level.all).to eq([Invoice.find(1).billing_city])
      expect(city_level.keys).to eq([Invoice.find(1).billing_city])
    end
  end

  describe 'slicing a level and loading a lower level' do
    it 'loads query level correctly when slicing one degenerate level above it' do
      city_level.slice_with('Boston')
      expect(invoice_level.all.sort_by(&:id)).to eq(Invoice.where(billing_city: 'Boston').order(:id))
    end

    it 'loads query level correctly when slicing two degenerate levels above it' do
      country_level.slice_with('USA')
      expect(invoice_level.all.sort_by(&:id)).to eq(Invoice.where(billing_country: 'USA').order(:id))
    end

    it 'loads query level correctly when slicing one query level above it' do
      invoice_level.slice_with('invoice-1')
      expect(invoice_line_level.all.sort_by(&:id)).to eq(Invoice.find(1).invoice_lines.sort_by(&:id))
    end

    it 'loads query level correctly when slicing a degenerate level above a different query level' do
      country_level.slice_with('USA')
      invoices = Invoice.where(billing_country: 'USA')
      invoice_lines = invoices.flat_map(&:invoice_lines).sort_by(&:id)
      expect(invoice_line_level.all.sort_by(&:id)).to eq(invoice_lines)
    end

    it 'loads degenerate level correctly when slicing a degenerate level above it' do
      country_level.slice_with('USA')
      invoices = Invoice.where(billing_country: 'USA')
      expect(city_level.all.sort).to eq(invoices.map(&:billing_city).uniq.sort)
    end
  end

  describe 'slicing a level and loading a higher level' do
    it 'loads query level correctly when slicing one query level below it' do
      invoice_line_level.slice_with(['invoice-line-1', 'invoice-line-6'])
      invoices = [InvoiceLine.find(1).invoice, InvoiceLine.find(6).invoice]
      expect(invoice_level.all.sort_by(&:id)).to eq(invoices)
    end

    it 'loads degenerate level correctly when slicing one query level below it' do
      invoice_level.slice_with('invoice-1')
      expect(city_level.all).to eq([Invoice.find(1).billing_city])
      expect(city_level.keys).to eq([Invoice.find(1).billing_city])
    end

    it 'loads degenerate level correctly when slicing two query levels below it' do
      invoice_line_level.slice_with(['invoice-line-1', 'invoice-line-6'])
      invoices = [InvoiceLine.find(1).invoice, InvoiceLine.find(6).invoice]
      cities = invoices.flat_map(&:billing_city)
      countries = invoices.flat_map(&:billing_country)
      expect(city_level.all).to eq(cities)
      expect(country_level.all).to eq(countries)
    end
  end

  describe 'fetching values up' do
    it 'returns the right record when using #recursive_value_lookup_up on same query level' do
      record = invoice_line_level.recursive_value_lookup_up(1, level: invoice_line_level)
      expect(record).to eq(InvoiceLine.find(1))
    end

    it 'returns the right record when using #recursive_value_lookup_up on query level above' do
      record = invoice_line_level.recursive_value_lookup_up(1, level: invoice_level)
      invoice_line = InvoiceLine.find(1)
      expect(record).to eq(invoice_line.invoice)
    end

    it 'returns the right record when using #recursive_value_lookup_up on direct degenerate level 1 level above' do
      record = invoice_level.recursive_value_lookup_up(1, level: city_level)
      expect(record).to eq(Invoice.find(1).billing_city)
    end

    it 'returns the right record when using #recursive_value_lookup_up on direct degenerate level 3 levels above' do
      record = invoice_level.recursive_value_lookup_up(1, level: country_level)
      expect(record).to eq(Invoice.find(1).billing_country)
    end

    it 'returns the right record when using #recursive_value_lookup_up on degenerate level above another query level' do
      record = invoice_line_level.recursive_value_lookup_up(1, level: country_level)
      invoice_line = InvoiceLine.find(1)
      expect(record).to eq(invoice_line.invoice.billing_country)
    end

    it 'returns the same value when using #recursive_value_lookup_up on same degenerate level' do
      value = city_level.recursive_value_lookup_up('Boston', level: city_level)
      expect(value).to eq('Boston')
    end

    it 'returns the right record when using #recursive_value_lookup_up on degenerate level above degenerate level' do
      record = city_level.recursive_value_lookup_up('Boston', level: country_level)
      expect(record).to eq('USA')
    end
  end

  describe 'fetching values down' do
    it 'returns the right record when using #recursive_value_lookup_down on same query level' do
      records = invoice_level.recursive_value_lookup_down(1, level: invoice_level)
      expect(records).to eq([Invoice.find(1)])
    end

    it 'returns right records when using #recursive_value_lookup_down on same query level with multiple records' do
      records = invoice_level.recursive_value_lookup_down([1, 2], level: invoice_level)
      expect(records).to eq([Invoice.find(1), Invoice.find(2)])
    end

    it 'returns the right record when using #recursive_value_lookup_down on query level below from query level' do
      records = invoice_level.recursive_value_lookup_down(1, level: invoice_line_level)
      invoice_lines = InvoiceLine.where(invoice_id: 1)
      expect(records).to eq(invoice_lines)
    end

    it 'returns the right record when using #recursive_value_lookup_down on query level below from degenerate level 1 level above' do
      records = city_level.recursive_value_lookup_down('Boston', level: invoice_level).sort_by(&:id)
      invoices = Invoice.where(billing_city: 'Boston').to_a.sort_by(&:id)
      expect(records).to eq(invoices)
    end

    it 'returns the right record when using #recursive_value_lookup_down on query level below from degenerate level 1 level above for multiple values' do
      records = city_level.recursive_value_lookup_down(['Boston', 'New York'], level: invoice_level).sort_by(&:id)
      invoices = Invoice.where(billing_city: ['Boston', 'New York']).to_a.sort_by(&:id)
      expect(records).to eq(invoices)
    end

    it 'returns the right record when using #recursive_value_lookup_down on query level below from degenerate level 3 levels above' do
      records = country_level.recursive_value_lookup_down('USA', level: invoice_level).sort_by(&:id)
      invoices = Invoice.where(billing_country: 'USA').to_a.sort_by(&:id)
      expect(records).to eq(invoices)
    end

    it 'returns the right record when using #recursive_value_lookup_down on query level below another query level from degenerate level' do
      records = country_level.recursive_value_lookup_down('USA', level: invoice_line_level).sort_by(&:id)
      invoice_lines = Invoice.where(billing_country: 'USA').flat_map(&:invoice_lines).sort_by(&:id)
      expect(records).to eq(invoice_lines)
    end

    it 'returns the right record when using #recursive_value_lookup_down on same degenerate level' do
      records = city_level.recursive_value_lookup_down('Boston', level: city_level)
      expect(records).to eq(['Boston'])
    end

    it 'returns the right record when using #recursive_value_lookup_down on degenerate level below degenerate level' do
      records = country_level.recursive_value_lookup_down('USA', level: city_level).sort
      cities = Invoice.where(billing_country: 'USA').map(&:billing_city).compact.uniq.sort
      expect(records).to eq(cities)
    end
  end
end