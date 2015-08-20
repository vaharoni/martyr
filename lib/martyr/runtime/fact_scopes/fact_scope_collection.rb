module Martyr
  module Runtime
    class FactScopeCollection < HashWithIndifferentAccess
      include Martyr::Registrable

      alias_method :scopes, :values

      def self.delegate_to_all_scopes(method_name, *args, &block)
        values.each {|x| x.send(method_name, *args, &block)}
      end

      # First executes on the main scope. If it does not support the level or metric, stop execution, otherwise execute
      # on sub facts.
      def decorate_scopes_if_supports(**options, &block)
        main_fact_supported = main_fact.decorate_if_supports(**options, &block)
        return false unless main_fact_supported
        sub_facts.each{|x| x.decorate_if_supports(**options, &block)}
        true
      end

      def sql
        # TODO: apply sub facts
        main_fact.scope_sql
      end

      # = Accessors

      def sub_facts
        except(:main)
      end

      def main_fact
        fetch(:main)
      end

    end
  end
end