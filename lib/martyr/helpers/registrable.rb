module Martyr
  module Registrable
    def register(object)
      self.[]=(object.name.to_s, object)
    end

    def find_or_nil(name)
      self.[](name.to_s)
    end

    def find_or_error(name)
      find_or_nil(name) || raise(Schema::Error.new "#{self.class.name}: Could not find `#{name}`")
    end
  end
end
