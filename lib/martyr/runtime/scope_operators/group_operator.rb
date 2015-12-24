module Martyr
  module Runtime
    class GroupOperator < BaseOperator

      attr_reader :field_alias

      def add_group(field_alias)
        @field_alias = field_alias
      end

      private

      def handle_outer(wrapper)
        wrapper.add_to_group_by(field_alias)
      end
    end
  end
end
