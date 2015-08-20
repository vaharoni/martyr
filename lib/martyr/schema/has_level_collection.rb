module Martyr
  module Schema
    module HasLevelCollection
      extend ActiveSupport::Concern

      included do
        attr_reader :levels
        delegate :lowest_level, :level_and_above, :find_level, :level_names, :has_level?, to: :levels
      end

    end
  end
end