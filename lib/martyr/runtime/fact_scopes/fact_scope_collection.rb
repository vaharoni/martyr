module Martyr
  module Runtime
    class FactScopeCollection < HashWithIndifferentAccess
      include Martyr::Registrable

      alias_method :scopes, :values
      delegate :set_null_scope, :null?, to: :main_fact

      def operators
        @operators ||= []
      end

      # Add the add_<operator> methods:
      #   add_select_operator_for_metric
      #   add_select_operator_for_dimension
      #   add_group_opeartor
      #   add_where_operator_for_dimension
      #   add_where_operator_for_metric
      [GroupOperator, SelectOperatorForMetric, SelectOperatorForDimension,
        WhereOperatorForDimension, WhereOperatorForMetric].each {|op| op.register_to(self)}

      # = Running

      def run
        ActiveRecord::Base.connection.execute(combined_sql)
      end

      def test
        run
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

      def combined_sql
        @combined_sql ||= combined_outer_sql
      end

      private

      def decorate_inner_scopes
        operators.each do |operator|
          operator.apply_on_inner(main_fact)
        end
        return false if null?
        sub_facts.each do |sub_fact_scope|
          operators.each do |operator|
            operator.apply_on_inner(sub_fact_scope)
          end
        end
        true
      end

      def join_sub_facts
        sub_facts.each {|x| x.add_to_join(main_fact)}
      end

      def combined_inner_scope
        decorate_inner_scopes
        join_sub_facts
        main_fact.run_scope
      end

      def combined_inner_sql
        combined_inner_scope.to_sql
      end

      def combined_outer_sql
        wrapper = SqlWrapper.new(combined_inner_sql)
        operators.each { |operator| operator.reapply_on_outer_wrapper(wrapper) }
        wrapper.to_sql
      end

      class SqlWrapper
        attr_reader :from_sql, :where_added
        attr_accessor :select, :group, :where

        def initialize(from_sql)
          @from_sql = from_sql
          @select = []
          @group = []

          # TODO: find a better way to solve this other than using Dummy.
          #       Note that the same approach is not doable for select and group by, since for these ActiveRecord
          #       requires the table to exist.
          @where = Dummy
          @where_added = false
        end

        def add_to_select(operand)
          @select << operand
        end

        def add_to_where(*args)
          @where = where.where(*args)
          @where_added = true
        end

        def add_to_group_by(operand)
          @group << operand
        end

        def to_sql
          sql = "SELECT #{select.join(', ')}" +
                 " FROM (#{from_sql}) martyr_wrapper"
          sql += " WHERE #{where.to_sql.match(/WHERE (.*)$/)[1]}" if where_added
          sql += " GROUP BY #{group.join(', ')}" if @group.present?
          sql
        end

        class Dummy < ActiveRecord::Base
        end
      end

    end
  end
end
