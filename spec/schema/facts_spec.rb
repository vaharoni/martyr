require 'spec_helper'

describe 'Schema Facts' do

  describe 'main_fact' do
    it 'works with basic example' do
      klass = Class.new(Martyr::Base).class_eval do
        main_fact do
          Post.all
        end
      end
      expect(klass.scope_query).to eq("SELECT \"posts\".* FROM \"posts\"")
    end
  end

end

