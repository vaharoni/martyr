$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'martyr'
require 'chinook_database'

RSpec.configure do |config|
  config.before :all do
    ChinookDatabase.connect
  end
end