module Martyr
  class Base

    # @return [Schema::Dimensions::DefinitionCollection]
    def self.dimension_definitions
      @dimension_definitions ||= Schema::DimensionDefinitionCollection.new(parent_schema_class)
    end

    class << self
      delegate :add_query_dimension, :use_shared_dimension, :add_degenerate_dimension, :add_time_dimension, to: :dimension_definitions
    end


    def self.main_fact

    end

    def self.sub_fact

    end

    def self.add_count_metric

    end

    def self.add_min_metric

    end

    def self.add_max_metric

    end

    def self.add_sum_metric

    end

    def self.add_custom_metric

    end

    def self.define_rollup

    end

    def self.martyr_schema_class?
      true
    end

    # @return [nil, Base]
    def self.parent_schema_class
      ancestors[1..-1].find{|x| x != Martyr::Base and x.respond_to?(:martyr_schema_class?)}
    end

    private_class_method :parent_schema_class
  end
end