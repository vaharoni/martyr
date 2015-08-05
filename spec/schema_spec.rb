require 'spec_helper'

describe 'Schema' do

  describe 'dimensions' do

    describe 'add_query_dimension' do
      it 'adds query dimension with defaults' do
        Class.new(Martyr::Base).add_query_dimension(:user).tap do |x|
          expect(x).to be_a(Martyr::Schema::QueryDimension)
          expect(x.name).to eq('user')
          expect(x.fetch_scope).to eq(User.all)
          expect(x.levels.length).to eq(1)
          expect(x.selected_level.name).to eq('id')
          x.selected_level.tap do |y|
            expect(y.name).to eq('id')
            expect(y.label).to eq('Id')
            expect(y.primary_key).to eq('id')
            expect(y.foreign_key).to eq('user_id')
          end
        end
      end

      it 'adds query dimension with provided options' do
        Class.new(Martyr::Base).add_query_dimension(:dummy, -> { Post.all }, levels: ['rating']).tap do |x|
          expect(x.name).to eq('dummy')
          expect(x.fetch_scope).to eq(Post.all)
          expect(x.levels.length).to eq(1)
          expect(x.selected_level.name).to eq('rating')
          x.selected_level.tap do |y|
            expect(y.name).to eq('rating')
            expect(y.label).to eq('Rating')
            expect(y.primary_key).to eq('rating')
            expect(y.foreign_key).to eq('dummy_rating')
          end
        end
      end

      it 'allows adding custom levels with block syntax' do
        Class.new(Martyr::Base).add_query_dimension(:user) do |x|
          x.add_level 'rating', label: 'User Rating', primary_key: 'rating_name', foreign_key: 'rating_id'
        end.levels.values.first.tap do |y|
          expect(y.name).to eq('rating')
          expect(y.label).to eq('User Rating')
          expect(y.primary_key).to eq('rating_name')
          expect(y.foreign_key).to eq('rating_id')
        end
      end

      it 'registers dimension in class' do
        Class.new(Martyr::Base).tap do |x|
          dimension = x.add_query_dimension(:user)
          expect(x.dimension_definitions.fetch(:user)).to eq(dimension)
        end
      end
    end

    describe 'use_shared_dimension' do
      it 'correctly references parent dimension' do
        parent = Class.new(Martyr::Base).tap { |x| x.add_query_dimension(:user) }
        Class.new(parent).use_shared_dimension(:user).tap do |x|
          expect(x).to be_a(Martyr::Schema::SharedDimensionWrapper)
          expect(x.dimension).to eq(parent.dimension_definitions.fetch(:user))
        end
      end

      it 'correctly registers it' do
        parent = Class.new(Martyr::Base).tap { |x| x.add_query_dimension(:user) }
        Class.new(parent).tap do |x|
          dimension = x.use_shared_dimension(:user)
          expect(x.dimension_definitions.fetch(:user)).to eq(dimension)
        end

      end

      it 'allows overriding base definitions' do
        parent = Class.new(Martyr::Base).tap { |x| x.add_query_dimension(:user, levels: ['id', 'category']) }
        child = Class.new(parent).tap { |x| x.use_shared_dimension(:user, use_level: 'category') }

        parent.dimension_definitions.fetch(:user).tap do |x|
          expect(x.selected_level.foreign_key).to eq('user_id')
        end

        child.dimension_definitions.fetch(:user).tap do |x|
          expect(x.selected_level.foreign_key).to eq('user_category')
        end
      end
    end

    describe 'add_degenerate_dimension' do
      it 'adds degenerate dimension with defaults' do
        Class.new(Martyr::Base).add_degenerate_dimension(:categorization, levels: ['sub_category', 'category']).tap do |x|
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
        Class.new(Martyr::Base).tap do |x|
          dimension = x.add_degenerate_dimension(:categorization, levels: ['sub_category', 'category'])
          expect(x.dimension_definitions.fetch(:categorization)).to eq(dimension)
        end
      end
    end

    describe 'add_time_dimension' do
      it 'adds time dimension with default levels' do
        Class.new(Martyr::Base).add_time_dimension(:created_at, column: :created_at).tap do |x|
          expect(x.levels.length).to eq(1)
          expect(x.selected_level.name).to eq('created_at')
          expect(x.selected_level.foreign_key).to eq('created_at')
        end
      end

    end
  end
end
