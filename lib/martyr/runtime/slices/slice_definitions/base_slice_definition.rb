module Martyr
  module Runtime
    class BaseSliceDefinition
      include ActiveModel::Model

      def initialize(*)
        super
        compile_operators
      end

      def null?
        !!@null
      end

      def self.null
        obj = new
        obj.send(:set_null) and return obj
      end

      protected

      def set_null
        @null = true
      end

      def compile_operators
        raise NotImplementedError
      end

    end
  end
end
