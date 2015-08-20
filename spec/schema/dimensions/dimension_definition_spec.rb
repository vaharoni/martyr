require 'spec_helper'

describe Martyr::Schema::DimensionDefinition do

  it 'allows defining levels correctly' do
    Martyr::Schema::DimensionDefinition.new :customer do
      degenerate_level :country
      degenerate_level :state
      query_level :name
    end.tap do |x|
      expect(x.levels.count).to eq(3)
    end
  end

end