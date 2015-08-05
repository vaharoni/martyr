$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'martyr'
require 'fixtures'

RSpec.configure do |config|
  config.before :all do
    Fixtures.setup
  end
end