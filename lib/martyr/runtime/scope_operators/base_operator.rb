module Martyr
  module Runtime

    class BaseOperator
      attr_reader :setup_block, :operation_args
      attr_accessor :fact_scope

      # Defines the method #add_<operator_name> to a class.
      #
      # @param klass [#operators] any class that has an instance method called operators
      def self.register_to(klass)
        current_class = self
        klass.class_eval do
          define_method "add_#{current_class.name.split('::').last.underscore}" do |*args, &block|
            operators << current_class.new(*args, &block)
          end
        end
      end

      def initialize(&setup_block)
        @setup_block = setup_block
      end

      def inspect
        to_hash.inspect
      end

      def to_hash
        {
          self.class.name.split('::').last.underscore =>
          (instance_variables - [:@setup_block, :@main_setup, :@fact_scope]).map{|x| {x => instance_variable_get(x)}}
        }
      end

      # = Running

      # There are 3 types of fact scopes that are handled:
      #   Inner main
      #     The main query fact scope.
      #   Inner sub
      #     A sub query fact scope.
      #   Outer wrapper
      #     The wrapper block on the query.
      #
      # Step 1
      #   Run the setup block if it is determined that the block can be supported for the current scope.
      #   The setup block is expected to run the appropriate operator "verb" on the provided operator instance, e.g.
      #   #add_select, #add_where, etc.
      #   The verb saves information that is to be applied on a fact scope - main, sub, or outer.
      #   The execution of the setup block is yielded self with the @fact_scope ivar initialized, so that
      #   support methods on self are available to the setup block.
      #
      # Step 2
      #   If the fact_scope is the main fact scope, a dup of the object is stored in @main_setup ivar, so that the
      #   result of running the setup block can be reused when reapplying on the outer wrapper.
      #
      # Step 3
      #   The concrete handle_inner is called for the current fact scope, which is assumed to be the main.
      #

      def apply_on_inner(fact_scope)
        return if fact_scope.is_a?(Runtime::SubFactScope) and !run_for_sub_fact?
        return unless supported_for?(fact_scope)
        with_fact_scope_ivar(fact_scope) { setup_block.call(self) }
        @main_setup = dup unless fact_scope.is_a?(Runtime::SubFactScope)
        dup.send(:handle_inner, fact_scope)
      end

      def reapply_on_outer_wrapper(wrapper)
        raise Internal::Error.new('@main_setup is not initialized. #apply_on_inner must be run on the ' +
          'main fact scope before calling #reapply_on_outer_wrapper') unless @main_setup.present?

        @main_setup.send(:handle_outer, wrapper)
      end

      # Concrete classes can optionally alias their particular verb (add_where, add_group, etc.) to this method
      def operate(*args)
        @operation_args = args
      end

      private

      # = Concrete class methods to override

      # @return [Boolean] whether the operator should be run for sub facts
      def run_for_sub_fact?
        false
      end

      # @return [Boolean] whether the particular fact_scope is supported by this operator
      def supported_for?(fact_scope)
        true
      end

      def handle_inner(fact_scope)
        # no-op
      end

      def handle_outer(wrapper)
        # no-op
      end

      # = Helpers

      def with_fact_scope_ivar(fact_scope)
        @fact_scope = fact_scope
        yield
      ensure
        @fact_scope = nil
      end
    end
  end
end
