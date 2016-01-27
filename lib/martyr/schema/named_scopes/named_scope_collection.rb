module Martyr
  module Schema
    class NamedScopeCollection < HashWithIndifferentAccess
      include Martyr::Registrable

      # = DSL

      def scope(name, proc)
        named_scope = NamedScope.new(name, proc)
        register(named_scope)
        add_to_cube_helper_module(named_scope)
        add_to_query_helper_module(named_scope)
      end

      def cube_helper_module
        @cube_helper_module ||= Module.new
      end

      def query_helper_module
        @query_helper_module ||= Module.new
      end

      private

      # Delegates all named scopes to #new_query_context_builder
      def add_to_cube_helper_module(named_scope)
        cube_helper_module.module_eval do
          delegate named_scope.name, to: :new_query_context_builder
        end
      end

      def add_to_query_helper_module(named_scope)
        query_helper_module.module_eval do
          define_method(named_scope.name) do |*args|
            named_scope.run(self, *args)
          end
        end
      end

    end
  end
end
