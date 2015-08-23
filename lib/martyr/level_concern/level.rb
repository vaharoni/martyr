module Martyr
  module Level
    extend ActiveSupport::Concern

    included do
      attr_accessor :collection
    end

    # Used for reflection
    def level_object?
      true
    end

  end
end

