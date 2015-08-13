module Martyr
  module Schema
    module AppliesOnDataWithGroup

      # Must provide #fact_key, #fact_alias, #name

      # @param scopeable [#update_scope]
      def apply_on_data(scopeable)
        scopeable.update_scope(dimension_name: name) do |scope|
          scope.select("#{fact_key} AS #{fact_alias}").group(fact_key)
        end
      end
    end
  end
end