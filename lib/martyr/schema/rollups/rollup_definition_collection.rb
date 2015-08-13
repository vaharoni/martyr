module Martyr
  module Schema
    class RollupDefinitionCollection < HashWithIndifferentAccess
      include Martyr::Registrable

      def define_rollup(name, block)
        register CustomRollup.new name: name, block: block
      end

    end
  end
end