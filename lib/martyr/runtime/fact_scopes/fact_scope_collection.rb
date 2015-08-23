module Martyr
  module Runtime
    class FactScopeCollection < HashWithIndifferentAccess
      include Martyr::Registrable

      alias_method :scopes, :values
      delegate :set_null_scope, :null?, to: :main_fact

      include Martyr::Delegators
      each_child_delegator :add_scope_operator, to: :values

      def add_scope_operator(operator)
        main_fact.add_scope_operator(operator)
        return false if null?
        sub_facts.each {|x| x.add_scope_operator(operator) }
        true
      end

      def sql
        # TODO: apply sub facts
        main_fact.scope_sql
      end

      def pretty_sql
        sql.gsub(', ', ",\n\t").
            gsub(/from/i, "\nFROM").
            gsub(/where/i, "\nWHERE").
            gsub(/and/i, "AND\n\t").
            gsub(/or/i, "OR\n\t").
            gsub(/inner join/i, "\n\tINNER JOIN").
            gsub(/group by/i, "\nGROUP BY").
            gsub(/having/i, "\nHAVING")
      end

      def run
        ActiveRecord::Base.connection.execute(sql)
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