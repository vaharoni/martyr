module Martyr
  module Schema
    class DimensionDefinition
      include ActiveModel::Validations

      validates_presence_of :name

      attr_reader :name, :levels, :selected_level
      delegate :add_level, to: :levels
      delegate :foreign_key, to: :selected_level

      # Receives a block used for calling add_level
      def initialize(name, use_level: nil, levels: [])
        @name = name.to_s
        @levels = LevelCollection.new(name.to_s)
        levels.each {|level_name| @levels.add_level level_name}
        yield self if block_given?
        @levels.add_level('id') if @levels.empty?
        @selected_level = use_level ? @levels.fetch(use_level) : @levels.values.first
      end

    end
  end
end