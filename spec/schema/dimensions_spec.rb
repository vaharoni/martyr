require 'spec_helper'

describe 'Schema Dimensions' do

  describe 'add_query_dimension' do
    it 'adds query dimension with defaults' do
      Class.new(Martyr::Cube).add_query_dimension(:customer).tap do |x|
        expect(x).to be_a(Martyr::Schema::QueryDimension)
        expect(x.name).to eq('customer')
        expect(x.fetch_scope).to eq(Customer.all)
        expect(x.levels.length).to eq(1)
        expect(x.selected_level.name).to eq('id')
        x.selected_level.tap do |y|
          expect(y.name).to eq('id')
          expect(y.title).to eq('Id')
          expect(y.primary_key).to eq('id')
          expect(y.foreign_key).to eq('customer_id')
        end
      end
    end

    it 'adds query dimension with provided options' do
      Class.new(Martyr::Cube).add_query_dimension(:dummy, -> { Customer.all }, levels: ['country']).tap do |x|
        expect(x.name).to eq('dummy')
        expect(x.fetch_scope).to eq(Customer.all)
        expect(x.levels.length).to eq(1)
        expect(x.selected_level.name).to eq('country')
        x.selected_level.tap do |y|
          expect(y.name).to eq('country')
          expect(y.title).to eq('Country')
          expect(y.primary_key).to eq('country')
          expect(y.foreign_key).to eq('dummy_country')
        end
      end
    end

    it 'allows adding custom levels with block syntax' do
      Class.new(Martyr::Cube).add_query_dimension(:customer) do |x|
        x.add_level 'country', title: 'Customer Country', primary_key: 'country', foreign_key: 'country'
      end.levels.values.first.tap do |y|
        expect(y.name).to eq('country')
        expect(y.title).to eq('Customer Country')
        expect(y.primary_key).to eq('country')
        expect(y.foreign_key).to eq('country')
      end
    end

    it 'registers dimension in class' do
      Class.new(Martyr::Cube).tap do |x|
        dimension = x.add_query_dimension(:customer)
        expect(x.dimension_definitions.fetch(:customer)).to eq(dimension)
      end
    end
  end

  describe 'use_shared_dimension' do
    it 'correctly references parent dimension' do
      parent = Class.new(Martyr::Cube).tap { |x| x.add_query_dimension(:customer) }
      Class.new(parent).use_shared_dimension(:customer).tap do |x|
        expect(x).to be_a(Martyr::Schema::SharedDimensionWrapper)
        expect(x.dimension).to eq(parent.dimension_definitions.fetch(:customer))
      end
    end

    it 'correctly registers it' do
      parent = Class.new(Martyr::Cube).tap { |x| x.add_query_dimension(:customer) }
      Class.new(parent).tap do |x|
        dimension = x.use_shared_dimension(:customer)
        expect(x.dimension_definitions.fetch(:customer)).to eq(dimension)
      end

    end

    it 'allows overriding base definitions' do
      parent = Class.new(Martyr::Cube).tap { |x| x.add_query_dimension(:customer, levels: ['id', 'country']) }
      child = Class.new(parent).tap { |x| x.use_shared_dimension(:customer, use_level: 'country') }

      parent.dimension_definitions.fetch(:customer).tap do |x|
        expect(x.selected_level.foreign_key).to eq('customer_id')
      end

      child.dimension_definitions.fetch(:customer).tap do |x|
        expect(x.selected_level.foreign_key).to eq('customer_country')
      end
    end
  end

  describe 'add_degenerate_dimension' do
    it 'adds degenerate dimension with defaults' do
      Class.new(Martyr::Cube).add_degenerate_dimension(:categorization, levels: ['sub_category', 'category']).tap do |x|
        expect(x).to be_a(Martyr::Schema::DegenerateDimension)
        expect(x.name).to eq('categorization')
        expect(x.levels.length).to eq(2)
        x.levels.values.tap do |levels|
          expect(levels.map(&:name)).to eq(['sub_category', 'category'])
          expect(levels.map(&:foreign_key)).to eq(['sub_category', 'category'])
        end
      end
    end

    it 'registers dimension in class' do
      Class.new(Martyr::Cube).tap do |x|
        dimension = x.add_degenerate_dimension(:categorization, levels: ['sub_category', 'category'])
        expect(x.dimension_definitions.fetch(:categorization)).to eq(dimension)
      end
    end
  end

  describe 'add_time_dimension' do
    it 'adds time dimension with default levels' do
      Class.new(Martyr::Cube).add_time_dimension(:invoice_date, column: :invoice_date).tap do |x|
        expect(x.levels.length).to eq(1)
        expect(x.selected_level.name).to eq('invoice_date')
        expect(x.selected_level.foreign_key).to eq('invoice_date')
      end
    end

  end
end
