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

    end
  end
end