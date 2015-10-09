require 'spec_helper'

describe 'Sub cube facts and elements' do
  let(:sub_cube) { MartyrSpec::DegeneratesAndBottomLevels.all.build.sub_cubes.first }

  it 'uses sub cube grain and metrics when those are not provided' do
    expect(sub_cube.elements.first.keys).to eq(sub_cube.grain.level_ids + sub_cube.metrics.metric_ids)
  end

  it 'has the right number of elements when asking for the sub cube grain' do
    expect(sub_cube.elements.count).to eq(sub_cube.facts.count)
  end

  it 'puts all the grain in the coordinates when asking for the sub cube grain' do
    expect(sub_cube.elements.first.coordinates.keys).to eq(sub_cube.grain.level_ids)
  end

  it 'groups by facts correctly when asking for less detailed grain' do
    elements = sub_cube.elements(levels: 'customers.country')
    expect(elements.map{|x| x.facts.count}.reduce(:+)).to eq(sub_cube.facts.count)
    expect(elements.first.facts.count).to satisfy {|x| x > 1}
    expect(elements.first['metrics.units_sold']).to eq(elements.first.facts.map{|x| x['metrics.units_sold']}.reduce(:+))
  end

  it 'returns right level of grain in the coordinates when asking for less detailed grain' do
    elements = sub_cube.elements(levels: 'customers.country')
    expect(elements.first.coordinates.keys).to eq(['customers.country'])
  end



  # TODO: if sub cube slice has low level, e.g. last name 'Aharoni', 'Meunier', and elements grain (e.g. in pivot mode) has higher
  # TODO: level country, then now the coordinates of an element basically need to include both the current country and the last name
  # TODO: to be fully correct. I suggest when such a thing happens to have the coordinates of the element taken from all the facts.
  # TODO: this mean I can safely remove the SubCubeGrain#merge_with_hash and need to find an alternative.
end
