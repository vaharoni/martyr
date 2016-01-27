module Martyr
  module Schema
    class NamedScope
      include ActiveModel::Model

      attr_reader :name, :proc

      def initialize(name, proc)
        @name = name.to_s
        @proc = proc
      end

      def run(query_context_builder, *args)
        query_context_builder.instance_exec(@proc, *args) do |proc, *args|
          proc.call(*args)
        end
      end

    end
  end
end
