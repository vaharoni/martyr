module Martyr
  module Schema
    class DimensionDefinition
      include ActiveModel::Model
      include Martyr::Schema::AppliesOnDataWithGroup

      attr_accessor :name, :fact_key, :fact_alias

      validates_presence_of :name

      def initialize(params={})
        super
        yield self if block_given?
        raise Schema::Error.new("#{name} dimension is invalid: #{errors.full_messages.join('; ')}") unless valid?
      end

      def normalize_alias(fact_alias)
        return unless fact_alias
        fact_alias.to_s.gsub('.', '_')
      end
    end
  end
end