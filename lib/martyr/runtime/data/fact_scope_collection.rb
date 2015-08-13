module Martyr
  module Runtime
    class FactScopeCollection < HashWithIndifferentAccess
      include Martyr::Registrable

      # Trickles down scope definitions to all children
      def update_scope(dimension_name: nil, metric_name: nil, &block)
        values.each do |fact_scope|
          fact_scope.update_scope(dimension_name: dimension_name, metric_name: metric_name, &block)
        end
      end

      def sql
        # TODO: apply sub facts
        main_fact.scope_sql
      end

      def sub_facts
        except(:main)
      end

      def main_fact
        fetch(:main)
      end

    end
  end
end