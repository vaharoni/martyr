module Martyr
  module Runtime
    class FactScopeCollection < HashWithIndifferentAccess
      include Martyr::Registrable

      alias_method :scopes, :values
      delegate :set_null_scope, :null?, to: :main_fact

      # = Building

      def add_scope_operator(operator)
        main_fact.add_scope_operator(operator.dup)
        return false if null?
        sub_facts.each {|x| x.add_scope_operator(operator.dup) }
        true
      end

      # = Running

      def run
        ActiveRecord::Base.connection.execute(combined_sql)
      end

      def test
        join_sub_facts
        main_fact.run_scope.first
        true
      end

      # = Accessors

      def sub_facts
        except(:main).values
      end

      def main_fact
        fetch(:main)
      end

      # = Access to SQL

      # @return [Array<String>] all select aliases in the combined SQL query
      def select_keys
        combined_scope.select_values.map{|x| x.split(' AS ').last }
      end

      def combined_sql
        join_sub_facts
        main_fact.scope_sql
      end

      def pretty_sql
        combined_sql.gsub(', ', ",\n\t").
            gsub(/from/i, "\nFROM").
            gsub(/where/i, "\nWHERE").
            gsub(/and/i, "AND\n\t").
            gsub(/or/i, "OR\n\t").
            gsub(/inner join/i, "\n\tINNER JOIN").
            gsub(/group by/i, "\nGROUP BY").
            gsub(/having/i, "\nHAVING")
      end

      private

      def join_sub_facts
        return if @join_sub_facts
        sub_facts.each {|x| x.add_to_join(main_fact)}
        @join_sub_facts = true
      end

      def combined_scope
        join_sub_facts
        main_fact.run_scope
      end

    end
  end
end
