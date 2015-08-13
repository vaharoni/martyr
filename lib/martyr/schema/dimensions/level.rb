module Martyr
  module Schema
    class Level

      attr_reader :name, :title, :primary_key, :label_key, :foreign_key

      def initialize(name, title: nil, primary_key: nil, label_key: nil, foreign_key: nil, dimension_name:)
        @name = name.to_s
        @title = title || name.to_s.titleize
        @primary_key = (primary_key || name).to_s
        @label_key = label_key || @primary_key
        @foreign_key = (foreign_key || "#{dimension_name}_#{name}").to_s
      end

    end
  end
end