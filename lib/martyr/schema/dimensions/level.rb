module Martyr
  module Schema
    class Level

      attr_reader :name, :label, :primary_key, :foreign_key

      def initialize(name, dimension_name:, label: nil, primary_key: nil, foreign_key: nil)
        @name = name.to_s
        @label = label || name.to_s.titleize
        @primary_key = (primary_key || name).to_s
        @foreign_key = (foreign_key || "#{dimension_name}_#{name}").to_s
      end

    end
  end
end