module Martyr
  module Level
    extend ActiveSupport::Concern

    included do
      attr_accessor :collection
    end

    def id
      "#{dimension_name}.#{name}"
    end

    # Used for reflection
    def level_object?
      true
    end

    def level_above
      @_level_above ||= collection.level_above(name)
    end

    def level_below
      @_level_below ||= collection.level_below(name)
    end

    def level_index
      @_level_index ||= collection.level_index(name)
    end
    alias_method :to_i, :level_index

    def query_level_below
      @_query_level_below ||= collection.query_level_below(name)
    end

    def level_and_above
      @_level_and_above ||= collection.level_and_above(name)
    end

    def level_and_below
      @_level_and_below ||= collection.level_and_below(name)
    end

  end
end

