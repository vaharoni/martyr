module Martyr
  class BaseSliceDefinition
    include ActiveModel::Model

    def initialize(*)
      super
      compile_operators
    end

    def null?
      !!@null
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
