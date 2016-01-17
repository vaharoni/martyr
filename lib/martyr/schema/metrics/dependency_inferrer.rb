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

      # @return [DependencyInferrer::Instance]
      def infer_from_block(depends_on: nil, fact_grain: nil, &block)
        instance = Instance.new(self, depends_on: depends_on, fact_grain: fact_grain)
        block.call(instance)
        instance
      end

      private

      # @param level [BaseLevelDefinition]
      def add_level(level)
        @level_keys_hash[level.id] = level.id
        level.helper_methods.each do |method_name|
          @level_keys_hash[method_name] = level.id
        end
      end

      class Instance
        def initialize(inferrer, depends_on: nil, fact_grain: nil)
          @inferrer = inferrer
          @depends_on_hash = {}
          @fact_grain_hash = {}
          @depends_on = depends_on == false ? false : Array.wrap(depends_on)
          @fact_grain = fact_grain == false ? false : Array.wrap(fact_grain)
        end

        # @return [Array<String>, []]
        #   if the user explicitly set depends_on: false, an empty array is returned
        #   if the user provided depends_on arguments, they are returned
        #   otherwise, the inferred value is used
        def depends_on
          return [] if @depends_on == false
          @depends_on.presence || @depends_on_hash.keys
        end

        # @return [Array<String>, []]
        #   if the user explicitly set fact_grain: false, an empty array is returned
        #   if the user provided fact_grain arguments, they are returned
        #   otherwise, the inferred value is used
        def fact_grain
          return [] if @fact_grain == false
          @fact_grain.presence || @fact_grain_hash.keys
        end

        def locate(*args)
          main_arg = args.first
          if main_arg.is_a?(String)
            infer_fact_grain(main_arg)
          elsif main_arg.is_a?(Hash)
            main_arg.keys.each do |arg|
              infer_fact_grain(arg)
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
