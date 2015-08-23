module Martyr
  module Level
    extend ActiveSupport::Concern

    included do
      attr_accessor :collection
      alias_method :to_i, :level_index
    end

    # Used for reflection
    def level_object?
      true
    end

    def level_index
      @_level_index ||= collection.level_index(name)
    end

  end
end

