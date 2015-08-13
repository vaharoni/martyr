require 'spec_helper'

describe 'Schema Facts' do

  describe 'main_fact' do
    it 'works with basic example' do
      klass = Class.new(Martyr::Cube).class_eval do
        main_fact do
          Customer.all
        end
      end
      expect(klass.scope_query).to eq("SELECT \"customers\".* FROM \"customers\"")
    end
  end

end

