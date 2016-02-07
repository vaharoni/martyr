module Martyr
  module Schema
    class DependencyInferrer

      attr_reader :level_keys_hash, :metric_keys_hash

      def initialize
        @cubes = []
        @level_keys_hash = {}
        @metric_keys_hash = {}
      end

      def add_cube_levels(cube)
        cube.supported_level_definitions.each do |level|
          add_level(level)
        end
        self
      end

      # We rely on adding metric one-by-one to avoid infinite recursion
      # @param metric [BaseMetric]
      def add_metric(metric)
        @metric_keys_hash[metric.name.to_s] = metric.id
        @metric_keys_hash[metric.id.to_s] = metric.id
      end

      # @return [#depends_on, #fact_grain] an object responding to these methods
      # The idea is that the block won't be evaluated if the user intervened with one of the options
      def infer_from_block(depends_on: nil, fact_grain: nil, &block)
        if (depends_on.nil? or depends_on == []) and (fact_grain.nil? or fact_grain == [])
          evaluator = BlockEvaluator.new(self)
          evaluator.instance_exec(&block)
          evaluator
        else
          UserValues.new(depends_on, fact_grain)
        end
      end

      private

      # @param level [BaseLevelDefinition]
      def add_level(level)
        @level_keys_hash[level.id] = level.id
        level.helper_methods.each do |method_name|
          @level_keys_hash[method_name] = level.id
        end
      end

      class UserValues
        attr_reader :depends_on, :fact_grain

        def initialize(depends_on, fact_grain)
          @depends_on = depends_on == false ? [] : Array.wrap(depends_on)
          @fact_grain = fact_grain == false ? [] : Array.wrap(fact_grain)
        end
      end

      class BlockEvaluator
        include Comparable

        def initialize(inferrer)
          @inferrer = inferrer
          @depends_on_hash = {}
          @fact_grain_hash = {}
        end

        def depends_on
          @depends_on_hash.keys
        end

        def fact_grain
          @fact_grain_hash.keys
        end

        def locate(*args)
          main_arg = args.first
          if main_arg.is_a?(String)
            infer_either(main_arg)
          elsif main_arg.is_a?(Hash)
            main_arg.keys.each do |arg|
              infer_either(arg)
            end
          end
          self
        end

        def fetch(id)
          infer_either(id)
          self
        end

        def [](key)
          infer_depends_on(key)
          self
        end

        def key_for(level_id)
          infer_fact_grain(level_id)
          self
        end

        def record_for(level_id)
          infer_fact_grain(level_id)
          self
        end

        def fact_key_for(level_id)
          infer_fact_grain(level_id)
          self
        end

        def <=>(_other)
          0
        end

        def coerce(other)
          [other, other]
        end

        private

        # @param candidate [String] a suspicious level ID that should be check against the white list
        # @return [nil, true] true if added
        def infer_fact_grain(candidate)
          level_id = @inferrer.level_keys_hash[candidate.to_s]
          return unless level_id.present?
          @fact_grain_hash[level_id] = true
        end

        # @param candidate [String] a suspicious metric ID that should be check against the white list
        # @return [nil, true] true if added
        def infer_depends_on(candidate)
          metric_id = @inferrer.metric_keys_hash[candidate.to_s]
          return unless metric_id.present?
          @depends_on_hash[metric_id] = true
        end

        def infer_either(candidate)
          infer_fact_grain(candidate) || infer_depends_on(candidate)
        end

        def method_missing(name, *args, &block)
          infer_either(name)
          self
        end
      end

    end
  end
end
