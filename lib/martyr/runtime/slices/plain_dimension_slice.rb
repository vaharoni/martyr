module Martyr
  module Runtime
    class PlainDimensionSlice
      include Martyr::LevelComparator
      include ActiveModel::Validations

      attr_reader :dimension, :level, :with, :without
      delegate :name, to: :dimension, prefix: true
      delegate :name, to: :level, prefix: true

      validate do
        errors.add(:base, "Slice on `#{dimension_name}`: cannot have both `with` and `without`") if with and without
        errors.add(:base, "Slice on `#{dimension_name}`: must have either `with` and `without`") unless with or without
      end

      # @param dimension [Schema::DimensionAssociation]
      def initialize(dimension)
        @dimension = dimension
      end

      # Sets the slice if this is the first time the dimension slice was referenced or if the level is equal to or lower
      # than the existing slice's level
      def set_slice(**options)
        level = dimension.find_level(options[:level])
        @level = more_detailed_level(level, @level)
        return unless @level == level
        @with = options[:with]
        @without = options[:without]
      end

      # Adds all supported levels including and above the sliced level
      def add_to_grain(grain)
        grain.add_granularity(dimension_name, level_name)
      end

      # @param fact_scopes [Runtime::FactScopeCollection]
      def add_to_where(fact_scopes)
        fact_scopes.decorate_scopes_if_supports(dimension_name: dimension_name, level_name: level_name) do |scope, fact_scope|
          level_key = fact_scope.level_key_for_where(level)
          if with.present?
            scope.where(level_key => with)
          elsif without.present?
            scope.where.not(level_key => with)
          end
        end
      end

    end
  end
end