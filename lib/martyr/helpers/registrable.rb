module Martyr
  module Registrable
    def register(object)
      send(:[]=, object.name.to_s, object)
    end

    def find_or_nil(name)
      send(:[], name.to_s)
    end

    def find_or_error(name)
      find_or_nil(name) || raise(Schema::Error.new "#{self.class.name}: Could not find `#{name}`")
    end
  end
end
