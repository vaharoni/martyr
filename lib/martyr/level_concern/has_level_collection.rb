module Martyr
  module HasLevelCollection
    extend ActiveSupport::Concern

    included do
      attr_reader :levels
      delegate :lowest_level, :level_above, :find_level, :level_names, :level_objects, :has_level?, to: :levels
    end

  end
end